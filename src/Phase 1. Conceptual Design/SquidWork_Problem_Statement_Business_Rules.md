# SquidWork - Problem Statement & Business Rules

**Dự án:** SquidWork - Freelance Marketplace Ecosystem (Mini-Upwork)  
**Nguồn:** `SquidWork_Database_Project_Report.pdf`  
**Phạm vi tài liệu:** Mô tả bài toán và các quy tắc nghiệp vụ được suy ra từ báo cáo. Các hướng dẫn môn học, tiêu chuẩn tham chiếu, ví dụ SQL, cấu hình kỹ thuật và kết quả seed không được xem là yêu cầu nghiệp vụ độc lập.

## 1. Problem Statement

### 1.1 Bối cảnh

Hoạt động thuê freelancer qua tin nhắn, bảng tính và các kênh rời rạc làm thông tin bị phân tán. Khó xác định chính xác:

- ai là người đăng một công việc;
- proposal nào đã được chọn;
- hợp đồng và các mốc bàn giao đang ở trạng thái nào;
- phiên bản bàn giao nào đã được nghiệm thu;
- khoản thanh toán nào đã thành công, thất bại hoặc đang chờ xử lý;
- đánh giá nào hợp lệ và thuộc về giao dịch nào.

Việc thiếu một nguồn dữ liệu thống nhất làm tăng nguy cơ dữ liệu trùng lặp, liên kết sai giữa các đối tượng, cập nhật trạng thái mâu thuẫn và khó truy vết lịch sử.

### 1.2 Bài toán cần giải quyết

SquidWork cần cung cấp một hệ thống dữ liệu cho marketplace thuê freelancer theo dự án. Hệ thống phải liên kết xuyên suốt vòng đời nghiệp vụ:

`User/Profile -> Job -> Proposal -> Contract -> Milestone -> Submission -> Payment -> Review`

Hệ thống phải bảo đảm rằng các bước trên được thực hiện bởi đúng chủ thể, đúng trạng thái và đúng tài nguyên; đồng thời lưu được lịch sử bàn giao, các lần thử thanh toán và các đánh giá phát sinh từ hợp đồng.

### 1.3 Mục tiêu nghiệp vụ

1. Cho phép Client đăng job, mô tả ngân sách và kỹ năng yêu cầu.
2. Cho phép Freelancer quản lý hồ sơ, kỹ năng, tìm job và gửi proposal.
3. Cho phép Client chọn proposal, tạo contract và tổ chức công việc bằng milestone.
4. Cho phép Freelancer nộp nhiều phiên bản bàn giao; Client duyệt hoặc yêu cầu chỉnh sửa.
5. Tạo nghĩa vụ thanh toán theo milestone và lưu riêng từng payment attempt.
6. Chỉ ghi nhận thanh toán thành công sau khi có kết quả xác minh đáng tin cậy.
7. Cho phép hai bên đánh giá sau khi contract hoàn tất.
8. Bảo vệ dữ liệu bằng ownership, role, trạng thái, khóa duy nhất, khóa ngoại và các kiểm tra miền giá trị.
9. Hỗ trợ báo cáo marketplace mà không làm sai lệch số liệu do nhân bản bản ghi khi JOIN.

### 1.4 Tác nhân và nhu cầu

| Tác nhân | Nhu cầu chính |
|---|---|
| Client | Đăng job, tìm người phù hợp, chọn proposal, quản lý tiến độ, duyệt bàn giao và thanh toán. |
| Freelancer | Quản lý hồ sơ/kỹ năng, ứng tuyển, nộp sản phẩm, theo dõi thanh toán và review. |
| Administrator | Quản lý user, role, skill, category và xem báo cáo theo quyền. |
| Payment Gateway | Trả về kết quả xác minh cho các payment attempt. |

### 1.5 Phạm vi MVP được báo cáo xác định

- Mỗi job tuyển một Freelancer trong mô hình MVP.
- Job dùng ngân sách `FIXED` và tiền tệ `USD` trong các luồng API được mô tả.
- Contract có thể ở trạng thái `PENDING` trước khi có milestone; chỉ được `ACTIVE` khi thỏa điều kiện kích hoạt.
- Payment là nghĩa vụ gắn với milestone; một payment có thể có nhiều attempt nhưng tối đa một attempt `SUCCEEDED`.
- Transaction type được triển khai trong MVP là `CHARGE`; `REFUND` và `PAYOUT` để dành cho phase sau.

## 2. Business Rules

### 2.1 Quy ước

- Mỗi quy tắc có mã ổn định dạng `BR-xxx`.
- **Nguồn** chỉ ra nội dung đến từ báo cáo hoặc là diễn giải trực tiếp từ lược đồ/API trong báo cáo.
- Các trạng thái viết bằng chữ hoa là giá trị miền của hệ thống.
- Quy tắc nghiệp vụ áp dụng cùng với kiểm tra quyền, ownership và trạng thái ở service/API; ràng buộc cơ sở dữ liệu là lớp bảo vệ bổ sung.

### 2.2 Tài khoản, vai trò và quyền sở hữu

| ID | Quy tắc nghiệp vụ | Nguồn |
|---|---|---|
| BR-001 | Mỗi tài khoản phải có một email duy nhất. | Báo cáo BR-01; `users.email` UNIQUE |
| BR-002 | Một người dùng có thể đồng thời có vai trò Client và Freelancer. | Báo cáo BR-02; mô hình role/profile chồng lấp |
| BR-003 | Mọi dữ liệu tạo mới phải truy được tới người dùng thực hiện thao tác. | Báo cáo BR-03 |
| BR-004 | Người dùng chỉ được sửa hoặc xóa tài nguyên thuộc quyền sở hữu của mình, trừ khi có quyền quản trị phù hợp. | Báo cáo BR-04 |
| BR-005 | Chỉ người dùng `ACTIVE` và có role phù hợp mới được thực hiện thao tác yêu cầu xác thực. Có profile không tự động cấp quyền. | Phần Security, Backend Architecture và API Contracts |
| BR-006 | Administrator có thể quản lý trạng thái tài khoản, nhưng không được tự nâng quyền và không được làm thay đổi lịch sử tài chính. | API `PATCH /api/admin/users/{id}/status` |
| BR-007 | Không được xóa dây chuyền dữ liệu lịch sử; thao tác xóa phải bị giới hạn bởi chính sách và quan hệ tham chiếu. | FK `ON DELETE RESTRICT`; phần Logical Design |

### 2.3 Job và kỹ năng

| ID | Quy tắc nghiệp vụ | Nguồn |
|---|---|---|
| BR-008 | Một Client có thể tạo nhiều Job; mỗi Job thuộc đúng một Client. | Báo cáo BR-06 |
| BR-009 | Job phải có tiêu đề, mô tả, category và ngân sách hợp lệ theo `budget_type`. | Báo cáo BR-07 |
| BR-010 | Trong MVP, job dùng `FIXED` và `USD`; `budget_min` phải dương và `budget_max >= budget_min`. | Data Dictionary/API Contracts |
| BR-011 | Job có các trạng thái `DRAFT`, `OPEN`, `CLOSED`, `CANCELLED`; chỉ `OPEN` mới được nhận proposal mới. | Báo cáo BR-08; schema `jobs` |
| BR-012 | Job đã quá hạn, đã đóng hoặc đã hủy không được nhận hoặc chấp nhận proposal mới. | Trigger proposal; BR-12 |
| BR-013 | Job chỉ tham chiếu tới category hợp lệ; skill gắn với job phải tồn tại trong danh mục skill. | FK `jobs.category_id`, `job_skills` |
| BR-014 | Freelancer có thể gắn nhiều skill với profile; cùng một cặp Freelancer-skill không được lặp. | PK `freelancer_skills(freelancer_user_id, skill_id)` |

### 2.4 Proposal và lựa chọn ứng viên

| ID | Quy tắc nghiệp vụ | Nguồn |
|---|---|---|
| BR-015 | Một Freelancer chỉ được có tối đa một proposal cho cùng một Job. | Báo cáo BR-09; unique nghiệp vụ |
| BR-016 | Freelancer không được gửi proposal cho Job do chính mình sở hữu. | Báo cáo BR-10; trigger proposal |
| BR-017 | Proposal chỉ được gửi cho Job đang `OPEN`, chưa quá hạn, đúng currency và đúng loại ngân sách MVP. | Trigger `tr_proposal_insert` |
| BR-018 | Proposal phải thuộc một Job và một Freelancer profile tồn tại. | FK `proposals` |
| BR-019 | Chỉ Client sở hữu Job mới được chấp nhận hoặc từ chối proposal của Job đó. | Báo cáo BR-11 |
| BR-020 | Một Job MVP chỉ có tối đa một proposal ở trạng thái `ACCEPTED`. | Functional UNIQUE trên proposal accepted |
| BR-021 | Khi một proposal được chấp nhận, các proposal còn lại phải được xử lý theo chính sách của Job; baseline của báo cáo cho phép tự động đánh dấu không được chọn. | Báo cáo BR-13 |
| BR-022 | Proposal có các trạng thái `SUBMITTED`, `ACCEPTED`, `REJECTED`, `WITHDRAWN`; trạng thái phải phản ánh đúng vòng đời proposal. | Schema `proposals` |

### 2.5 Contract và milestone

| ID | Quy tắc nghiệp vụ | Nguồn |
|---|---|---|
| BR-023 | Mỗi proposal được chấp nhận chỉ tạo tối đa một contract. | Báo cáo BR-14; `contracts.proposal_id` UNIQUE |
| BR-024 | Contract chỉ được tạo từ proposal `ACCEPTED`. | Báo cáo BR-15; trigger contract |
| BR-025 | Contract phải giữ đúng proposal, Job, Client và Freelancer; không được ghép chéo các đối tượng từ các giao dịch khác. | Composite FK của `contracts` |
| BR-026 | Trong MVP, một Job chỉ có tối đa một Contract. | `contracts.job_id` UNIQUE |
| BR-027 | Contract mới bắt đầu ở `PENDING`; có thể chưa có milestone ở trạng thái này. | Báo cáo điều chỉnh DBML mới |
| BR-028 | Contract chỉ được chuyển sang `ACTIVE` khi có ít nhất một milestone. | Báo cáo BR-16 |
| BR-029 | Nếu contract yêu cầu phân bổ toàn bộ giá trị theo milestone, tổng amount của các milestone phải bằng `contract.total_amount`. | Báo cáo BR-18; luồng Activate contract |
| BR-030 | Mỗi milestone có một `sequence_no` nguyên dương duy nhất trong phạm vi contract. | Báo cáo BR-17 |
| BR-031 | Chỉ Freelancer thuộc contract mới được gửi submission cho milestone của contract đó. | Báo cáo BR-19; composite FK submissions |
| BR-032 | Chỉ Client thuộc contract mới được duyệt submission hoặc yêu cầu chỉnh sửa. | Báo cáo BR-20 |
| BR-033 | Submission phải có version tăng dần, không tái sử dụng trong cùng milestone; payload đã nộp không được âm thầm sửa. | Schema `submissions` |
| BR-034 | Một milestone chỉ có tối đa một submission `ACCEPTED`; submission `PENDING` chưa có reviewer, thời điểm duyệt hoặc feedback. | Data Dictionary `submissions` |
| BR-035 | Milestone chỉ hoàn tất sau khi kết quả được Client chấp nhận; yêu cầu chỉnh sửa phải tạo vòng đời submission tiếp theo. | Submission API và trạng thái milestone |
| BR-036 | Contract không được chuyển `COMPLETED` nếu còn milestone bắt buộc chưa hoàn thành hoặc nghĩa vụ thanh toán chưa thành công. | Báo cáo BR-21 và điều chỉnh DBML |
| BR-037 | Sau khi contract `ACTIVE`, thay đổi quan trọng về giá trị hoặc điều khoản phải theo chính sách sửa đổi và phải giữ được lịch sử. | Báo cáo BR-22 |
| BR-038 | Contract có các trạng thái `PENDING`, `ACTIVE`, `COMPLETED`, `CANCELLED`; chuyển trạng thái phải tuân theo điều kiện của từng trạng thái. | Schema `contracts` và trigger contract |

### 2.6 Payment và payment transaction

| ID | Quy tắc nghiệp vụ | Nguồn |
|---|---|---|
| BR-039 | Mỗi milestone có tối đa một Payment trong MVP. | Báo cáo BR-23; `payments.milestone_id` UNIQUE |
| BR-040 | Payment phải tham chiếu tới milestone hợp lệ và đúng contract; Client/Freelancer trong payment phải khớp hai bên của contract. | Báo cáo BR-24; composite FK payments |
| BR-041 | Payment chỉ được tạo cho milestone đã `COMPLETED`; amount và currency lấy từ nghĩa vụ đã xác định. | API `POST /api/milestones/{id}/payments` |
| BR-042 | Số tiền payment phải lớn hơn 0 và không vượt quá số tiền được phép của milestone. | Báo cáo BR-25 |
| BR-043 | Một Payment có thể có nhiều payment attempt, nhưng tối đa một attempt `CHARGE` ở trạng thái `SUCCEEDED`. | Báo cáo BR-26; functional UNIQUE |
| BR-044 | Retry với cùng `idempotency_key` không được tạo thêm giao dịch thành công cho cùng nghĩa vụ. Payload khác với request ban đầu phải bị từ chối. | Báo cáo BR-27; phần Transactions |
| BR-045 | Việc gửi yêu cầu thanh toán hoặc tạo attempt không phải bằng chứng thanh toán thành công. | Báo cáo BR-28 |
| BR-046 | Payment chỉ được chuyển `SUCCEEDED` khi có kết quả xác minh đáng tin cậy từ gateway hoặc luồng đối soát được ủy quyền. | Báo cáo BR-29; webhook API |
| BR-047 | Attempt phải bắt đầu ở `INITIATED`; attempt đã kết thúc không được âm thầm đổi trạng thái hoặc bằng chứng gateway. | Data Dictionary `payment_transactions` |
| BR-048 | Attempt `SUCCEEDED` phải có `provider_reference`; cùng provider và provider reference không được lặp. | Schema payment transactions |
| BR-049 | Mọi thay đổi trạng thái tài chính phải nguyên tử, có thể truy vết và không được tạo ra hai kết quả thành công cho cùng payment. | Báo cáo BR-30; transaction/locking |
| BR-050 | Payment có các trạng thái `PENDING`, `PROCESSING`, `SUCCEEDED`, `FAILED`; transaction MVP chỉ dùng loại `CHARGE`. | Schema payments/payment_transactions |

### 2.7 Review và rating

| ID | Quy tắc nghiệp vụ | Nguồn |
|---|---|---|
| BR-051 | Review chỉ được tạo khi contract đủ điều kiện đánh giá; trong MVP, contract phải `COMPLETED`. | Báo cáo BR-31; Review API |
| BR-052 | Reviewer và reviewee phải là hai người dùng khác nhau. | Báo cáo BR-32 |
| BR-053 | Reviewer và reviewee phải là hai bên tham gia contract được review. | Báo cáo BR-33 |
| BR-054 | Một người dùng chỉ được review một đối tác tối đa một lần cho mỗi contract. | Báo cáo BR-34; UNIQUE(contract_id, reviewer_user_id) |
| BR-055 | Rating phải là số nguyên từ 1 đến 5. | Báo cáo BR-35; CHECK `reviews.rating` |
| BR-056 | Điểm tổng hợp phải được tính từ các review hợp lệ; không được nhập tùy ý từ client request. | Báo cáo BR-05 |
| BR-057 | Sửa hoặc xóa review phải tuân theo chính sách kiểm duyệt và lưu vết; baseline MVP không cho sửa/xóa review sau khi tạo. | Báo cáo BR-36 và trigger review |

### 2.8 Báo cáo và dữ liệu dẫn xuất

| ID | Quy tắc nghiệp vụ | Nguồn |
|---|---|---|
| BR-058 | Gross paid volume chỉ cộng các transaction `CHARGE` có trạng thái `SUCCEEDED`; không được coi là doanh thu hoa hồng của nền tảng. | Query Q06/Q15 |
| BR-059 | Freelancer chưa có review phải có `review_count = 0` và `average_rating = NULL`, không gán rating 0. | View `freelancer_rating_summary` |
| BR-060 | Tiến độ milestone không chứng minh payment đã thành công; tiến độ và thanh toán phải được báo cáo độc lập. | View `contract_milestone_progress` |
| BR-061 | Các báo cáo có phân trang phải có giới hạn kích thước và thứ tự sắp xếp được cho phép; dữ liệu KPI phải tránh nhân bản do JOIN. | API Contracts và Queries |

## 3. Quy tắc kỹ thuật hỗ trợ nghiệp vụ

Các mục dưới đây là ràng buộc triển khai hoặc tiêu chí chất lượng được báo cáo nêu ra. Chúng hỗ trợ Business Rules nhưng không thay thế chúng:

- Dùng PK/FK/UNIQUE/CHECK/NOT NULL để bảo vệ toàn vẹn dữ liệu.
- Dùng `ON DELETE RESTRICT` và `ON UPDATE RESTRICT` để giữ lịch sử.
- Dùng transaction tại service cho accept proposal, activate contract, submit delivery và finalize payment.
- Kiểm quyền theo principal, role, trạng thái `ACTIVE` và ownership trước khi ghi dữ liệu.
- Dùng `DECIMAL` cho tiền, `BIGINT` cho định danh và thời gian UTC.
- Không trả `password_hash`, secret hoặc stack trace/SQL chi tiết ra API.
- Dùng migration có phiên bản; không sửa migration đã áp dụng tại chỗ.

## 4. Điểm cần chốt trước khi phát triển chính thức

Các nội dung sau được báo cáo nêu dưới dạng “theo chính sách” hoặc giới hạn MVP nhưng chưa định nghĩa đầy đủ trong tài liệu nguồn. Chúng cần được Product Owner/giảng viên xác nhận trước khi coi là quy tắc bắt buộc:

1. Khi một proposal được chấp nhận, các proposal còn lại sẽ tự động `REJECTED`, `WITHDRAWN` hay giữ trạng thái lịch sử riêng?
2. Chính sách sửa đổi contract sau `ACTIVE` cho phép thay đổi trường nào, ai phê duyệt và lưu phiên bản ra sao?
3. Review có được sửa/xóa trong một khoảng thời gian hay luôn bất biến ngoài MVP?
4. Điều kiện chính xác để một Job quá hạn tự chuyển trạng thái hoặc bị khóa nhận proposal là gì?
5. Khi thanh toán thất bại, có giới hạn số lần retry hoặc thời hạn xử lý hay không?
6. Các luồng `HOURLY`, `REFUND` và `PAYOUT` sẽ được mở rộng theo quy tắc nào ở phase sau?

