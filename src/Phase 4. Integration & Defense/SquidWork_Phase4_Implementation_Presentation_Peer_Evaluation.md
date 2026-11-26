# SquidWork - Phase 4 Implementation Guide

## 1. Mục tiêu Phase 4

Phase 4 biến database và các quy tắc nghiệp vụ thành một sản phẩm có thể demo:

1. Backend REST kết nối MySQL.
2. UI đơn giản cho các luồng chính.
3. Kiểm thử các quyền, trạng thái và transaction quan trọng.
4. Chuẩn bị live group presentation.
5. Thu thập và tổng hợp peer evaluation.

## 2. Stack đề xuất

### Backend

Chọn **Java Spring Boot** vì báo cáo đã định hướng tích hợp Java và JPA:

- Spring Web: REST API.
- Spring Data JPA: repository và mapping entity.
- Spring Validation: kiểm tra DTO.
- Spring Security: authentication và role authorization.
- MySQL Connector/J: kết nối MySQL 8.4.
- Flyway: quản lý migration.
- BCrypt: hash password.

### Frontend

Chọn một UI đơn giản:

- React/Vite nếu nhóm quen JavaScript; hoặc
- Thymeleaf + Bootstrap nếu muốn chạy một ứng dụng Spring Boot duy nhất.

Đối với demo lớp học, Thymeleaf + Bootstrap là lựa chọn nhanh nhất; React phù hợp nếu cần UI tách riêng và trình bày đẹp hơn.

## 3. Kiến trúc triển khai

```text
Browser/UI
    |
    v
REST Controller -> Application Service -> Repository/JPA -> MySQL
                         |
                         +-> Validation, Authorization, Transaction
```

### Trách nhiệm từng lớp

| Lớp        | Trách nhiệm                                                          |
| ---------- | -------------------------------------------------------------------- |
| Controller | Nhận request, lấy principal, gọi service, trả DTO và HTTP status.    |
| DTO        | Chỉ chứa dữ liệu vào/ra; không trả entity hoặc `password_hash`.      |
| Service    | Kiểm role, `ACTIVE`, ownership, trạng thái và ranh giới transaction. |
| Repository | Truy vấn, JOIN, phân trang và khóa pessimistic khi cần.              |
| Database   | PK/FK/UNIQUE/CHECK/trigger bảo vệ toàn vẹn dữ liệu.                  |
| UI         | Hiển thị form, danh sách, trạng thái, lỗi và kết quả thao tác.       |

## 4. Cấu trúc project gợi ý

```text
src/main/java/com/squidwork/
  auth/
  user/
  job/
  proposal/
  contract/
  milestone/
  payment/
  review/
  report/
  common/
src/main/resources/
  db/migration/
  templates/          # nếu dùng Thymeleaf
  static/
```

Mỗi module nên có `Controller`, `Service`, `Repository`, `Entity` và `DTO`. Không cần tạo abstraction riêng nếu module chỉ có một implementation.

## 5. Luồng triển khai theo thứ tự

### Bước 1 - Khởi tạo database

1. Chạy migration DDL của Phase 3.
2. Kiểm tra 18 bảng, 25 FK, 22 trigger và 2 view.
3. Chạy seed DML trong transaction theo thứ tự parent-child.
4. Chạy các query kiểm tra fixture.

```properties
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false
spring.flyway.enabled=true
```

### Bước 2 - Authentication và authorization

- Đăng ký: kiểm email duy nhất, BCrypt password và tạo `UserSummary`.
- Đăng nhập: tạo session hoặc JWT.
- Mỗi request đã xác thực lấy `user_id` từ principal, không lấy actor từ body.
- Kiểm tra `user.status = ACTIVE`.
- Kiểm role và ownership trước khi gọi service nghiệp vụ.

### Bước 3 - Làm các luồng MVP theo thứ tự

| Thứ tự | Luồng             | Endpoint chính                          | Kết quả cần demo                                 |
| -----: | ----------------- | --------------------------------------- | ------------------------------------------------ |
|      1 | Tìm job           | `GET /api/jobs`                         | Lọc theo category, skill, budget, phân trang.    |
|      2 | Tạo job           | `POST /api/jobs`                        | Client ACTIVE tạo job FIXED/USD.                 |
|      3 | Gửi proposal      | `POST /api/jobs/{id}/proposals`         | Chặn self-proposal và proposal trùng.            |
|      4 | Accept proposal   | `POST /api/proposals/{id}/accept`       | Khóa job, chọn một winner, tạo contract PENDING. |
|      5 | Activate contract | `POST /api/contracts/{id}/activate`     | Kiểm milestone và tổng tiền trước khi ACTIVE.    |
|      6 | Nộp bàn giao      | `POST /api/milestones/{id}/submissions` | Tạo version mới và file metadata.                |
|      7 | Duyệt/revise      | `POST /api/submissions/{id}/review`     | Client ACCEPTED hoặc yêu cầu chỉnh sửa.          |
|      8 | Payment           | `POST /api/milestones/{id}/payments`    | Tạo một payment cho milestone đã hoàn tất.       |
|      9 | Review            | `POST /api/contracts/{id}/reviews`      | Hai bên đánh giá sau COMPLETED.                  |
|     10 | Admin report      | `GET /api/reports/marketplace`          | Hiển thị KPI từ view/query tổng hợp.             |

### Bước 4 - Thiết kế transaction

Đặt `@Transactional` ở service:

- **Accept proposal:** khóa Job → kiểm owner/trạng thái → khóa Proposal → tạo Contract → đóng Job → commit.
- **Activate contract:** khóa Contract → kiểm ít nhất một milestone và tổng amount → chuyển `ACTIVE`.
- **Submit:** khóa Contract/Milestone → cấp `MAX(version)+1` → ghi Submission/File → đổi milestone `SUBMITTED`.
- **Finalize payment:** xác minh callback → khóa Contract/Milestone/Payment/Attempt → cập nhật đồng thời.

Không giữ DB lock khi gọi payment gateway bên ngoài. Với deadlock `1213`, rollback và retry bằng transaction mới với số lần giới hạn.

## 6. UI tối giản cần có

| Màn hình           | Thành phần                                              |
| ------------------ | ------------------------------------------------------- |
| Login/Register     | Email, password, role/profile.                          |
| Job list           | Search, category, skill, budget, status, pagination.    |
| Job detail         | Mô tả, skills, ngân sách, danh sách proposal.           |
| Create job         | Title, description, category, budget, skills, deadline. |
| Freelancer profile | Headline, bio, hourly rate, skills, experience.         |
| Contract detail    | Participants, terms, total, status, milestones.         |
| Submission review  | Version, file metadata, accept/revision feedback.       |
| Payment status     | Amount, status, attempts, idempotency result.           |
| Review form        | Rating 1-5, comment.                                    |
| Admin dashboard    | Users/jobs/contracts/payment volume/rating summary.     |

UI chỉ cần hiển thị trạng thái và lỗi dễ hiểu. Không hiển thị stack trace, SQL, password hash hoặc secret.

## 7. API contract và HTTP status

| Tình huống                                      | Status |
| ----------------------------------------------- | -----: |
| Request hợp lệ tạo tài nguyên                   |  `201` |
| Đọc/cập nhật thành công                         |  `200` |
| Dữ liệu đầu vào sai                             |  `400` |
| Chưa xác thực                                   |  `401` |
| Thiếu quyền/không ownership                     |  `403` |
| Không tìm thấy tài nguyên                       |  `404` |
| Xung đột trạng thái, duplicate hoặc idempotency |  `409` |
| Nghiệp vụ chưa hỗ trợ, ví dụ `HOURLY` trong MVP |  `422` |

Nên dùng một error response thống nhất:

```json
{
  "code": "PROPOSAL_NOT_ALLOWED",
  "message": "Job is not open for new proposals",
  "traceId": "..."
}
```
