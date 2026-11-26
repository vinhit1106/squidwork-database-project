# SquidWork - Phase 2: Foreign Key Definitions & Normalization Proofs

**Nguồn:** `SquidWork_Database_Project_Report.pdf`, mục 2.3-2.4, trang PDF 9-13.  
**Phạm vi:** Tóm tắt baseline hiện tại; phương án chuẩn hóa là đề xuất, chưa phải thay đổi schema đã triển khai.

## 1. Foreign Key Definitions

Schema có **25 khóa ngoại: 18 FK đơn và 7 FK ghép**. Các cột tham chiếu dùng `BIGINT` tương thích; bộ cột được tham chiếu có `PRIMARY KEY` hoặc `UNIQUE`. Tất cả FK dùng `ON DELETE RESTRICT` và `ON UPDATE RESTRICT` để bảo vệ lịch sử, không xóa dây chuyền.

| # | Khóa ngoại ở bảng con | Tham chiếu bảng cha | Ý nghĩa |
|---|---|---|---|
| 1 | `user_roles(user_id)` | `users(id)` | Tài khoản được cấp role phải tồn tại. |
| 2 | `user_roles(role_id)` | `roles(id)` | Role phải hợp lệ. |
| 3 | `client_profiles(user_id)` | `users(id)` | Client profile dùng chung định danh user. |
| 4 | `freelancer_profiles(user_id)` | `users(id)` | Freelancer profile dùng chung định danh user. |
| 5 | `freelancer_skills(freelancer_user_id)` | `freelancer_profiles(user_id)` | Kỹ năng thuộc Freelancer có profile. |
| 6 | `freelancer_skills(skill_id)` | `skills(id)` | Skill phải tồn tại. |
| 7 | `jobs(client_user_id)` | `client_profiles(user_id)` | Chủ job phải có Client profile. |
| 8 | `jobs(category_id)` | `job_categories(id)` | Category của job phải hợp lệ. |
| 9 | `job_skills(job_id)` | `jobs(id)` | Kỹ năng yêu cầu thuộc job tồn tại. |
| 10 | `job_skills(skill_id)` | `skills(id)` | Skill yêu cầu phải tồn tại. |
| 11 | `proposals(job_id)` | `jobs(id)` | Proposal thuộc job tồn tại. |
| 12 | `proposals(freelancer_user_id)` | `freelancer_profiles(user_id)` | Ứng viên phải có Freelancer profile. |
| 13 | `contracts(proposal_id, job_id, freelancer_user_id)` | `proposals(id, job_id, freelancer_user_id)` | Proposal, job và Freelancer phải khớp nhau. |
| 14 | `contracts(job_id, client_user_id)` | `jobs(id, client_user_id)` | Client của contract phải là chủ job. |
| 15 | `milestones(contract_id)` | `contracts(id)` | Milestone thuộc contract tồn tại. |
| 16 | `submissions(milestone_id, contract_id)` | `milestones(id, contract_id)` | Không nộp chéo milestone/contract. |
| 17 | `submissions(contract_id, submitted_by_user_id)` | `contracts(id, freelancer_user_id)` | Người nộp là Freelancer của contract. |
| 18 | `submissions(contract_id, reviewer_user_id)` | `contracts(id, client_user_id)` | Người duyệt là Client của contract. |
| 19 | `submission_files(submission_id)` | `submissions(id)` | File gắn đúng phiên bản bàn giao. |
| 20 | `payments(contract_id, client_user_id, freelancer_user_id)` | `contracts(id, client_user_id, freelancer_user_id)` | Hai bên thanh toán khớp contract. |
| 21 | `payments(milestone_id, contract_id)` | `milestones(id, contract_id)` | Payment thuộc đúng milestone/contract. |
| 22 | `payment_transactions(payment_id)` | `payments(id)` | Attempt thuộc payment tồn tại. |
| 23 | `reviews(contract_id)` | `contracts(id)` | Review phải gắn contract tồn tại. |
| 24 | `reviews(reviewer_user_id)` | `users(id)` | Reviewer phải tồn tại. |
| 25 | `reviews(reviewee_user_id)` | `users(id)` | Reviewee phải tồn tại. |

**Lưu ý:** `reviewer_user_id` của submission được phép `NULL` khi chưa duyệt; cần thêm `CHECK` cho tổ hợp trạng thái/thông tin duyệt. FK chỉ bảo vệ quan hệ dữ liệu, không thay thế kiểm quyền người gọi. Với review, ba FK riêng chưa đủ chứng minh hai user là hai bên của contract; điều kiện này cần trigger/service kiểm tra.

## 2. Normalization Proofs (3NF/BCNF)

### 2.1 Tiêu chí chứng minh

- **FD:** Phụ thuộc hàm được xác định từ quy tắc nghiệp vụ, không suy ra từ dữ liệu mẫu.
- **Khóa ứng viên:** Superkey tối thiểu. `UNIQUE` có cột nullable không mặc nhiên là khóa ứng viên của toàn quan hệ.
- **3NF:** Với mọi FD không tầm thường `X -> A`, `X` là superkey hoặc `A` là thuộc tính thuộc ít nhất một khóa ứng viên.
- **BCNF:** Với mọi FD không tầm thường `X -> A`, `X` phải là superkey. BCNF suy ra 3NF.

Kết quả dưới đây theo tập FD nghiệp vụ được báo cáo lựa chọn; `K -> all` nghĩa là khóa `K` xác định toàn bộ thuộc tính của quan hệ.

### 2.2 Các quan hệ đạt BCNF theo tập FD đã nêu

| Quan hệ | Khóa ứng viên | FD chính và lập luận |
|---|---|---|
| `users` | `id`; `email` | Mỗi khóa `-> all`; email được chuẩn hóa và duy nhất. |
| `roles` | `id`; `name` | Mỗi khóa `-> all`; tên role duy nhất. |
| `user_roles` | `(user_id, role_id)` | Cặp khóa `-> created_at`; không phụ thuộc riêng từng thành phần. |
| `client_profiles` | `user_id` | `user_id -> all`; mỗi user có tối đa một Client profile. |
| `freelancer_profiles` | `user_id` | `user_id -> all`; không giả định kinh nghiệm quyết định đơn giá. |
| `skills` | `id`; `name` | Mỗi khóa `-> all`; tên skill duy nhất. |
| `freelancer_skills` | `(freelancer_user_id, skill_id)` | Cả cặp `-> proficiency_level, years_experience`; không có phụ thuộc bộ phận. |
| `job_categories` | `id`; `name` | Mỗi khóa `-> all`; thuộc tính category không sao chép vào job. |
| `jobs` | `id` | `id -> all`; `(id, client_user_id)` chỉ là superkey không tối thiểu. |
| `job_skills` | `(job_id, skill_id)` | Quan hệ chỉ gồm hai thuộc tính khóa; không có FD không tầm thường với determinant không là superkey theo miền đã chọn. |
| `contracts` | `id`; `proposal_id`; `job_id` | Mỗi khóa `-> all`; `UNIQUE(job_id)` của MVP làm `job_id -> client_user_id` có determinant là khóa. |
| `milestones` | `id`; `(contract_id, sequence_no)` | Mỗi khóa `-> all`; không có FD nội bảng khác gây vi phạm. `submitted_at` là cache cần đồng bộ với submission. |
| `submission_files` | `id` | `id -> all`; không giả định `file_url` duy nhất. |
| `reviews` | `id`; `(contract_id, reviewer_user_id)` | Mỗi khóa `-> all`; reviewer chỉ đánh giá một lần mỗi contract. |

Trong phạm vi các FD đã xác định ở trên, mọi determinant không tầm thường đều là superkey, nên các quan hệ này đạt BCNF và 3NF.

### 2.3 Các ngoại lệ chưa đạt 3NF/BCNF

| Quan hệ | Khóa ứng viên | FD gây vi phạm | Kết luận theo báo cáo |
|---|---|---|---|
| `proposals` | `id`; `(job_id, freelancer_user_id)` | `job_id -> currency_code`. `job_id` không là superkey; currency là thuộc tính không khóa phụ thuộc một phần vào khóa ghép. | 1NF; chưa đạt 2NF, 3NF, BCNF. |
| `submissions` | `id`; `(milestone_id, version)` | `milestone_id -> contract_id, submitted_by_user_id`. `milestone_id` không là superkey khi một mốc có nhiều phiên bản. | 1NF; chưa đạt 2NF, 3NF, BCNF. |
| `payments` | `id`; `milestone_id` | `id -> contract_id -> client_user_id, freelancer_user_id, currency_code`. `contract_id` không là superkey vì một contract có nhiều payment. | 2NF; chưa đạt 3NF/BCNF do phụ thuộc bắc cầu. |
| `payment_transactions` | `id`; `idempotency_key` | `id -> payment_id -> amount` theo mô hình thu đủ nghĩa vụ. `payment_id` không là superkey vì một payment có nhiều attempt. | 2NF; chưa đạt 3NF/BCNF do phụ thuộc bắc cầu. |

Khóa thay thế `id` không loại được vi phạm chuẩn hóa trên các khóa ứng viên khác. Tương tự, FK ghép và trigger giữ dữ liệu nhất quán nhưng không loại bỏ phụ thuộc hàm gây dư thừa.

### 2.4 Phương án loại bỏ các phụ thuộc gây vi phạm

| Quan hệ | Điều chỉnh đề xuất | Đánh đổi |
|---|---|---|
| `proposals` | Bỏ `currency_code`, lấy qua `jobs`. | Không còn snapshot currency riêng của proposal. |
| `submissions` | Bỏ `contract_id`, `submitted_by_user_id`; lấy qua milestone và contract. | Mất các FK ghép trực tiếp hiện dùng để bảo vệ người nộp/contract. |
| `payments` | Bỏ `client_user_id`, `freelancer_user_id`, `currency_code`; lấy qua contract. | Cần JOIN để lấy participants/currency. |
| `payment_transactions` | Bỏ `amount`, lấy qua payment. | Giảm bằng chứng số tiền được lưu riêng ở từng attempt. |

Các phép loại bỏ trên xử lý các FD vi phạm đã chỉ ra; giá trị bị loại có thể tái tạo qua các FK tới khóa cha. Trước khi áp dụng phải đánh giá lại toàn bộ FD, cập nhật API/ràng buộc và kiểm thử. **Baseline hiện tại có 14/18 quan hệ được báo cáo kết luận đạt BCNF theo tập FD đã chọn; 4 quan hệ là ngoại lệ có chủ đích. Không kết luận toàn bộ schema đã đạt 3NF/BCNF.**
