# SquidWork

> **Đồ án Cơ sở dữ liệu - INT1313 - Nhóm Squid**

SquidWork là mô hình cơ sở dữ liệu cho một sàn freelance kiểu Mini-Upwork. Đồ án mô tả luồng từ lúc Client đăng Job, Freelancer gửi Proposal, đến khi hình thành Contract, Milestone, Payment và Review.

## Nội dung chính

- Lược đồ quan hệ gồm **18 bảng, 141 cột và 25 khóa ngoại**.
- Hai profile `client_profiles` và `freelancer_profiles` dùng shared primary key, cho phép specialization chồng lấp.
- Các bảng liên kết `user_roles`, `freelancer_skills` và `job_skills` biểu diễn quan hệ nhiều-nhiều.
- Ràng buộc dữ liệu bằng PK, FK, UNIQUE, CHECK, trigger và transaction locking.
- Phân tích chuẩn hóa từ 1NF đến BCNF, trong đó các ngoại lệ có chủ đích được giữ để hỗ trợ snapshot, đối soát và bảo vệ FK ghép.
- **22 trigger** bảo vệ vòng đời Proposal, Contract, Milestone, Submission, Payment, Transaction và Review.
- **2 view tổng hợp** cho rating Freelancer và tiến độ Milestone.
- **15 truy vấn SQL** cho tìm kiếm, báo cáo marketplace, thanh toán, xếp hạng và theo dõi tiến độ.

## Tài liệu

- [`SquidWork_Database_Report.pdf`](docs/SquidWork_Database_Report.pdf) - Bản xem nhanh.
- [`SquidWork_Database_Report.docx`](docs/SquidWork_Database_Report.docx) - Bản báo cáo chính.

## Thành viên

Lê Minh Thiện (N24DCCN167) - Nguyễn Ngọc Vinh (N24DCCN183) - Nguyễn Tuấn Vỹ (N24DCCN184)
