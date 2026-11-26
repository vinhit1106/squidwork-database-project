# SquidWork - Phase 3: DDL, DML, Complex Queries, Triggers & Views

**Nguồn:** `SquidWork_Database_Project_Report.pdf`, mục 3.1-3.5.  
**Mục tiêu:** Tóm tắt script triển khai và các truy vấn minh họa; SQL bên dưới là bản rút gọn để dễ đọc.

## 1. SQL DDL Script

### 1.1 Quy ước triển khai

- Tạo schema thử nghiệm `mini_upwork` với `utf8mb4`.
- Tạo **18 bảng, 141 cột, 25 khóa ngoại**.
- Khai báo PK/UNIQUE trước, sau đó thêm FK và CHECK.
- Dùng `BIGINT` cho định danh, `DECIMAL(14,2)` cho tiền, `TIMESTAMP` UTC cho thời gian.
- Dùng `VARCHAR` kèm CHECK cho domain trạng thái; không dùng `FLOAT` cho tiền.
- Dùng migration có phiên bản; migration đã áp dụng không sửa tại chỗ.
- Không tắt FK/CHECK và không dùng `--force` để bỏ qua lỗi.

### 1.2 DDL mẫu

```sql
CREATE TABLE users (
    id BIGINT NOT NULL AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT ck_users_status CHECK (status IN ('ACTIVE', 'SUSPENDED'))
) ENGINE = InnoDB;
```

```sql
ALTER TABLE contracts
    ADD CONSTRAINT fk_contracts_proposal_source
    FOREIGN KEY (proposal_id, job_id, freelancer_user_id)
    REFERENCES proposals (id, job_id, freelancer_user_id)
    ON DELETE RESTRICT ON UPDATE RESTRICT;

CREATE UNIQUE INDEX uq_transactions_one_success
    ON payment_transactions (
        payment_id,
        ((CASE WHEN status = 'SUCCEEDED' THEN 1 ELSE NULL END))
    );
```

`CHECK` chỉ kiểm tra điều kiện trong cùng một hàng. Điều kiện tổng milestone bằng `contract.total_amount` được kiểm tra khi activate contract trong transaction, có khóa contract cha.

## 2. Mock Data Insertion (DML)

### 2.1 Quy mô fixture

| Bảng | Số hàng | Bảng | Số hàng |
|---|---:|---|---:|
| `users` | 1,200 | `jobs` | 2,100 |
| `roles` | 3 | `proposals` | 6,300 |
| `user_roles` | 1,051 | `contracts` | 600 |
| `client_profiles` | 250 | `milestones` | 1,200 |
| `freelancer_profiles` | 800 | `submissions` | 1,100 |
| `skills` | 120 | `submission_files` | 1,000 |
| `freelancer_skills` | 2,400 | `payments` | 600 |
| `job_categories` | 24 | `payment_transactions` | 600 |
| `job_skills` | 4,200 | `reviews` | 400 |

### 2.2 Thứ tự chèn

`categories + users -> roles/profiles + skills -> jobs -> proposals -> contracts -> milestones -> submissions/files -> payments/attempts -> reviews`

Seed được chia transaction theo nhóm, tuân thủ FK/CHECK. Dữ liệu cố ý sai chỉ dùng trong negative tests và được rollback. Không dùng dữ liệu cá nhân thật hoặc mật khẩu đăng nhập chung.

### 2.3 DML mẫu

```sql
INSERT INTO skills (name, is_active)
VALUES ('Database Modeling', TRUE);

INSERT INTO freelancer_skills
       (freelancer_user_id, skill_id, proficiency_level, years_experience)
VALUES (201, LAST_INSERT_ID(), 'INTERMEDIATE', 2.0);
```

Fixture đại diện có nhiều trạng thái Job/Proposal/Contract, 50 user đồng thời có cả hai profile, mỗi contract có hai milestone 500 USD, và 100 milestone có version submission thứ hai. Kết quả đối soát được báo cáo: 450 payment `SUCCEEDED`, 50 `FAILED`, 50 `PROCESSING`, 50 `PENDING`; gross paid volume của các charge thành công là 225,000 USD.

## 3. Complex Queries

Báo cáo có **15 truy vấn**; cả 15 được chạy thành công trên fixture. Bảng dưới đây tóm tắt mục tiêu và kỹ thuật chính.

| ID | Mục tiêu | Kỹ thuật SQL chính |
|---|---|---|
| Q01 | Freelancer có đủ skill 1 và 2, kinh nghiệm >= 3 năm | `JOIN`, `GROUP BY`, `HAVING COUNT(DISTINCT ...)` |
| Q02 | Job `OPEN`, category 1, ngân sách giao nhau 800-1200, đủ hai skill | `EXISTS` kép, lọc miền |
| Q03 | Đếm proposal theo job của Client, kể cả job chưa có proposal | `LEFT JOIN`, conditional aggregation |
| Q04 | Xếp hạng Client đăng nhiều job, bỏ `DRAFT` | CTE, `DENSE_RANK()` |
| Q05 | Tỷ lệ proposal accepted của Freelancer có ít nhất 5 proposal | `GROUP BY`, `HAVING`, tỷ lệ aggregate |
| Q06 | Gross paid volume theo tháng | `JOIN`, `DATE_FORMAT`, `SUM` |
| Q07 | Thống kê payment theo currency và status | `GROUP BY`, `COUNT`, `SUM` |
| Q08 | Contract active có milestone quá hạn | `EXISTS`, mốc thời gian `as_of` |
| Q09 | Milestone active chưa có submission | `JOIN`, `NOT EXISTS` |
| Q10 | Hàng chờ Client review, phân trang ổn định | `JOIN`, keyset pagination (`id > :last_seen_id`) |
| Q11 | Freelancer rating cao nhất với ít nhất 3 review | View, `DENSE_RANK()` |
| Q12 | Tổng tiền Client đã thanh toán thành công | `JOIN`, `GROUP BY`, tránh đếm attempt trùng |
| Q13 | Job `OPEN` chưa có proposal | Anti-join (`LEFT JOIN ... IS NULL`) |
| Q14 | Hiệu suất Freelancer không nhân bản số liệu | CTE, `LEFT JOIN`, correlated subquery |
| Q15 | KPI tổng quan marketplace | Scalar subqueries, independent aggregates |

### 3.1 Các mẫu truy vấn tiêu biểu

**Q01 - đủ tập kỹ năng**

```sql
SELECT u.id, u.full_name, f.experience_years
  FROM users AS u
  JOIN freelancer_profiles AS f ON f.user_id = u.id
  JOIN freelancer_skills AS fs ON fs.freelancer_user_id = f.user_id
 WHERE u.status = 'ACTIVE'
   AND f.experience_years >= 3
   AND fs.skill_id IN (1, 2)
 GROUP BY u.id, u.full_name, f.experience_years
HAVING COUNT(DISTINCT fs.skill_id) = 2
 ORDER BY f.experience_years DESC, u.id
 LIMIT 20;
```

**Q03 - giữ job không có proposal**

```sql
SELECT j.id, j.title,
       COUNT(p.id) AS proposal_count,
       SUM(CASE WHEN p.status = 'ACCEPTED' THEN 1 ELSE 0 END) AS accepted_count
  FROM jobs AS j
  LEFT JOIN proposals AS p ON p.job_id = j.id
 WHERE j.client_user_id = :client_id
 GROUP BY j.id, j.title
 ORDER BY proposal_count DESC, j.id;
```

**Q08 - milestone quá hạn**

```sql
SELECT c.id, c.title
  FROM contracts AS c
 WHERE c.status = 'ACTIVE'
   AND EXISTS (
       SELECT 1
         FROM milestones AS m
        WHERE m.contract_id = c.id
          AND m.status <> 'COMPLETED'
          AND m.due_at < :as_of_utc
   )
 ORDER BY c.id;
```

**Q15 - KPI marketplace**

```sql
SELECT
    (SELECT COUNT(*) FROM users) AS users_count,
    (SELECT COUNT(*) FROM jobs) AS jobs_count,
    (SELECT COUNT(*) FROM proposals) AS proposals_count,
    (SELECT COUNT(*) FROM contracts) AS contracts_count,
    (SELECT COUNT(*) FROM contracts WHERE status = 'COMPLETED')
        AS completed_contracts,
    (SELECT COALESCE(SUM(amount), 0)
       FROM payment_transactions
      WHERE status = 'SUCCEEDED'
        AND transaction_type = 'CHARGE') AS gross_usd_volume;
```

### 3.2 Điểm kiểm chứng chung

- Dùng `COUNT(p.id)` thay cho `COUNT(*)` khi `LEFT JOIN` để job không có proposal trả về 0.
- Dùng `NOT EXISTS` thay cho `NOT IN` ở truy vấn anti-join để tránh bẫy `NULL`.
- Chỉ cộng `CHARGE` có `SUCCEEDED`; không cộng failed attempt và không gọi gross volume là doanh thu nền tảng.
- Tổng hợp từng tập dữ liệu trước khi JOIN để tránh nhân bản số liệu.
- Các chỉ mục baseline được báo cáo gồm `jobs(category_id, status)`, `jobs(client_user_id, created_at)`, `proposals(job_id, status, created_at)`, `reviews(reviewee_user_id, created_at)` và chỉ mục báo cáo payment transaction.

## 4. Triggers

Báo cáo triển khai **22 trigger BEFORE**. Hai trigger tiêu biểu:

### 4.1 `tr_proposal_insert`

**Mục đích:** chặn proposal không hợp lệ ngay trước khi ghi.

**Điều kiện kiểm tra:**

- Freelancer không phải chủ Job.
- Job đang `OPEN` và chưa quá deadline.
- Proposal mới ở trạng thái `SUBMITTED`.
- Currency khớp Job.
- Job dùng `FIXED` trong MVP.

```sql
CREATE TRIGGER tr_proposal_insert
BEFORE INSERT ON proposals
FOR EACH ROW
BEGIN
    DECLARE v_owner BIGINT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_currency CHAR(3);
    DECLARE v_budget VARCHAR(20);
    DECLARE v_deadline DATE;

    SELECT client_user_id, status, currency_code, budget_type, deadline
      INTO v_owner, v_status, v_currency, v_budget, v_deadline
      FROM jobs
     WHERE id = NEW.job_id
     FOR UPDATE;

    IF v_owner = NEW.freelancer_user_id
       OR v_status <> 'OPEN'
       OR NEW.status <> 'SUBMITTED'
       OR v_currency <> NEW.currency_code
       OR (v_deadline IS NOT NULL AND v_deadline < UTC_DATE())
       OR v_budget <> 'FIXED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid proposal owner, job state, budget or currency';
    END IF;
END;
```

### 4.2 `tr_contract_update`

**Mục đích:** bảo vệ vòng đời contract.

**Điều kiện chính:**

- Contract chỉ được tạo từ proposal `ACCEPTED`.
- Chuyển `PENDING -> ACTIVE` phải có ít nhất một milestone và tổng milestone bằng `total_amount`.
- Không cho chuyển từ trạng thái terminal (`COMPLETED`/`CANCELLED`) về trạng thái đang chạy.

Các kiểm tra tổng hợp phải thực hiện trong transaction, khóa contract cha; trigger dùng `SIGNAL SQLSTATE '45000'` để từ chối dữ liệu không hợp lệ.

## 5. Views

### 5.1 `freelancer_rating_summary`

```sql
CREATE VIEW freelancer_rating_summary AS
SELECT f.user_id,
       COUNT(r.id) AS review_count,
       ROUND(AVG(r.rating), 2) AS average_rating
  FROM freelancer_profiles AS f
  LEFT JOIN (
      reviews AS r
      INNER JOIN contracts AS c
              ON c.id = r.contract_id
             AND c.status = 'COMPLETED'
  ) ON r.reviewee_user_id = f.user_id
 AND c.freelancer_user_id = f.user_id
 GROUP BY f.user_id;
```

**Ý nghĩa:** Tổng hợp số review và rating của Freelancer chỉ trên contract `COMPLETED`. Freelancer chưa có review vẫn xuất hiện với `review_count = 0`, `average_rating = NULL`.

### 5.2 `contract_milestone_progress`

```sql
CREATE VIEW contract_milestone_progress AS
SELECT c.id AS contract_id,
       c.status AS contract_status,
       COUNT(m.id) AS milestone_count,
       SUM(CASE WHEN m.status = 'COMPLETED' THEN 1 ELSE 0 END)
           AS completed_count,
       COALESCE(SUM(m.amount), 0) AS allocated_amount,
       ROUND(
           100.0 * SUM(CASE WHEN m.status = 'COMPLETED' THEN 1 ELSE 0 END)
           / NULLIF(COUNT(m.id), 0), 2
       ) AS completion_percent
  FROM contracts AS c
  LEFT JOIN milestones AS m ON m.contract_id = c.id
 GROUP BY c.id, c.status;
```

**Ý nghĩa:** Cung cấp số milestone, số milestone hoàn tất, số tiền đã phân bổ và tỷ lệ hoàn thành. Tỷ lệ tiến độ không chứng minh payment đã thành công.

## 6. Kết quả Phase 3

- DDL baseline: 18 bảng, 141 cột, 25 FK.
- DML fixture: 18 bảng với dữ liệu liên kết đúng thứ tự parent–child.
- Complex queries: 15 truy vấn, bao phủ JOIN, subquery, CTE, window function và aggregation.
- Trigger: 22 trigger BEFORE cho proposal, contract, milestone, submission, file, payment, transaction và review.
- View: 2 view tổng hợp cho rating Freelancer và tiến độ milestone.

