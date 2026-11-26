
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE reviews;
TRUNCATE TABLE payment_transactions;
TRUNCATE TABLE payments;
TRUNCATE TABLE submission_files;
TRUNCATE TABLE submissions;
TRUNCATE TABLE milestones;
TRUNCATE TABLE contracts;
TRUNCATE TABLE proposals;
TRUNCATE TABLE job_skills;
TRUNCATE TABLE jobs;
TRUNCATE TABLE job_categories;
TRUNCATE TABLE freelancer_skills;
TRUNCATE TABLE skills;
TRUNCATE TABLE user_roles;
TRUNCATE TABLE client_profiles;
TRUNCATE TABLE freelancer_profiles;
TRUNCATE TABLE roles;
TRUNCATE TABLE users;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TEMPORARY TABLE seed_numbers (n INT NOT NULL PRIMARY KEY);
INSERT INTO seed_numbers (n)
SELECT 1 + d0.n + 10*d1.n + 100*d2.n + 1000*d3.n + 10000*d4.n
FROM (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d0
CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d3
CROSS JOIN (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d4;

INSERT INTO users (id, email, password_hash, full_name, status, created_at, updated_at)
SELECT n, CONCAT('user', n, '@example.com'), CONCAT('hash_', n), CONCAT('User ', n),
       IF(MOD(n, 20) = 0, 'INACTIVE', 'ACTIVE'), DATE_SUB(NOW(), INTERVAL MOD(n, 365) DAY), DATE_SUB(NOW(), INTERVAL MOD(n, 365) DAY)
FROM seed_numbers WHERE n <= 1200;

INSERT INTO roles (id, name, description) VALUES
 (1,'CLIENT','Client account'), (2,'FREELANCER','Freelancer account'), (3,'ADMIN','System administrator');

INSERT INTO user_roles (user_id, role_id, created_at)
SELECT n, IF(n <= 250, 1, IF(n <= 1050, 2, 3)), NOW()
FROM seed_numbers WHERE n <= 1051;

INSERT INTO client_profiles (user_id, company_name, description, country_code, created_at, updated_at)
SELECT n, CONCAT('Client Company ', n), CONCAT('Client profile ', n), ELT(1 + MOD(n, 3), 'VN','US','SG'), NOW(), NOW()
FROM seed_numbers WHERE n <= 250;

INSERT INTO freelancer_profiles (user_id, headline, bio, hourly_rate, currency_code, experience_years, portfolio_url, created_at, updated_at)
SELECT 251 + n, CONCAT('Freelancer specialist ', n), CONCAT('Freelancer biography ', n), 10 + MOD(n, 90), 'USD', MOD(n, 16), CONCAT('https://portfolio.example.com/', n), NOW(), NOW()
FROM seed_numbers WHERE n <= 800;

INSERT INTO skills (id, name, is_active, created_at, updated_at)
SELECT n, CONCAT('Skill ', n), TRUE, NOW(), NOW() FROM seed_numbers WHERE n <= 120;

INSERT INTO freelancer_skills (freelancer_user_id, skill_id, proficiency_level, years_experience)
SELECT 252 + MOD(n - 1, 800), 1 + MOD(n - 1, 120), ELT(1 + MOD(n, 3), 'BEGINNER','INTERMEDIATE','EXPERT'), 1 + MOD(n, 100) / 10.0
FROM seed_numbers WHERE n <= 2400;

INSERT INTO job_categories (id, name, description, is_active, created_at, updated_at)
SELECT n, CONCAT('Category ', n), CONCAT('Job category ', n), TRUE, NOW(), NOW() FROM seed_numbers WHERE n <= 24;

INSERT INTO jobs (id, client_user_id, category_id, title, description, budget_type, budget_min, budget_max, currency_code, status, deadline, created_at, updated_at)
SELECT n, 1 + MOD(n - 1, 250), 1 + MOD(n - 1, 24), CONCAT('Job posting ', n), CONCAT('Job description ', n), IF(MOD(n, 2) = 0, 'FIXED', 'HOURLY'), 100 + n, 500 + n, 'USD', ELT(1 + MOD(n, 4), 'OPEN','IN_PROGRESS','CLOSED','DRAFT'), DATE_ADD(CURDATE(), INTERVAL MOD(n, 90) DAY), NOW(), NOW()
FROM seed_numbers WHERE n <= 2100;

INSERT INTO job_skills (job_id, skill_id)
SELECT
  1 + MOD(n - 1, 2100),
  1 + MOD(MOD(n - 1, 2100) + ((n - 1) DIV 2100), 120)
FROM seed_numbers WHERE n <= 4200;

INSERT INTO proposals (id, job_id, freelancer_user_id, cover_letter, proposed_amount, currency_code, proposed_duration_days, status, created_at, updated_at)
SELECT n, 1 + MOD(n - 1, 2100), 252 + MOD((n - 1) * 17, 800), CONCAT('Cover letter ', n), 200 + n, 'USD', 5 + MOD(n, 30), IF(n <= 600, 'ACCEPTED', 'SUBMITTED'), NOW(), NOW()
FROM seed_numbers WHERE n <= 6300;

INSERT INTO contracts (id, proposal_id, job_id, client_user_id, freelancer_user_id, title, terms, total_amount, currency_code, status, start_at, end_at, created_at, updated_at)
SELECT p.id, p.id, p.job_id, j.client_user_id, p.freelancer_user_id, CONCAT('Contract ', p.id), CONCAT('Contract terms ', p.id), p.proposed_amount, p.currency_code, IF(p.id <= 100, 'COMPLETED', 'ACTIVE'), NOW(), IF(p.id <= 100, DATE_ADD(NOW(), INTERVAL 30 DAY), NULL), NOW(), NOW()
FROM proposals p JOIN jobs j ON j.id = p.job_id WHERE p.id <= 600;

INSERT INTO milestones (id, contract_id, sequence_no, title, description, amount, due_at, status, submitted_at, completed_at, created_at, updated_at)
SELECT n, 1 + MOD(n - 1, 600), 1 + ((n - 1) DIV 600), CONCAT('Milestone ', n), CONCAT('Milestone description ', n), 100 + n, DATE_ADD(NOW(), INTERVAL 15 DAY), IF(n <= 600, 'COMPLETED', 'PENDING'), IF(n <= 600, NOW(), NULL), IF(n <= 600, NOW(), NULL), NOW(), NOW()
FROM seed_numbers WHERE n <= 1200;

INSERT INTO submissions (id, milestone_id, contract_id, version, submitted_by_user_id, note, status, reviewer_user_id, review_feedback, reviewed_at, created_at, updated_at)
SELECT n, n, m.contract_id, 1, c.freelancer_user_id, CONCAT('Submission note ', n), 'APPROVED', c.client_user_id, CONCAT('Feedback ', n), NOW(), NOW(), NOW()
FROM milestones m JOIN contracts c ON c.id = m.contract_id JOIN seed_numbers s ON s.n = m.id WHERE s.n <= 1100;

INSERT INTO submission_files (id, submission_id, file_name, file_url, file_type, file_size, created_at)
SELECT n, n, CONCAT('submission_', n, '.pdf'), CONCAT('https://files.example.com/', n, '.pdf'), 'application/pdf', 10000 + n, NOW()
FROM seed_numbers WHERE n <= 1000;

INSERT INTO payments (id, milestone_id, contract_id, client_user_id, freelancer_user_id, amount, currency_code, status, created_at, updated_at)
SELECT n, n, m.contract_id, c.client_user_id, c.freelancer_user_id, m.amount, 'USD', IF(n <= 300, 'PAID', 'PENDING'), NOW(), NOW()
FROM milestones m JOIN contracts c ON c.id = m.contract_id JOIN seed_numbers s ON s.n = m.id WHERE s.n <= 600;

INSERT INTO payment_transactions (id, payment_id, transaction_type, provider, provider_reference, idempotency_key, amount, status, created_at, updated_at)
SELECT n, n, 'CHARGE', 'DEMO_PAY', CONCAT('ref_', n), CONCAT('idem_', n), p.amount, 'SUCCEEDED', NOW(), NOW()
FROM payments p JOIN seed_numbers s ON s.n = p.id WHERE s.n <= 600;

INSERT INTO reviews (id, contract_id, reviewer_user_id, reviewee_user_id, rating, comment, created_at, updated_at)
SELECT n, n, c.client_user_id, c.freelancer_user_id, 1 + MOD(n, 5), CONCAT('Review ', n), NOW(), NOW()
FROM contracts c JOIN seed_numbers s ON s.n = c.id WHERE s.n <= 400;

DROP TEMPORARY TABLE seed_numbers;

SELECT 'users' table_name, COUNT(*) row_count FROM users
UNION ALL SELECT 'roles', COUNT(*) FROM roles
UNION ALL SELECT 'user_roles', COUNT(*) FROM user_roles
UNION ALL SELECT 'client_profiles', COUNT(*) FROM client_profiles
UNION ALL SELECT 'freelancer_profiles', COUNT(*) FROM freelancer_profiles
UNION ALL SELECT 'skills', COUNT(*) FROM skills
UNION ALL SELECT 'freelancer_skills', COUNT(*) FROM freelancer_skills
UNION ALL SELECT 'job_categories', COUNT(*) FROM job_categories
UNION ALL SELECT 'jobs', COUNT(*) FROM jobs
UNION ALL SELECT 'job_skills', COUNT(*) FROM job_skills
UNION ALL SELECT 'proposals', COUNT(*) FROM proposals
UNION ALL SELECT 'contracts', COUNT(*) FROM contracts
UNION ALL SELECT 'milestones', COUNT(*) FROM milestones
UNION ALL SELECT 'submissions', COUNT(*) FROM submissions
UNION ALL SELECT 'submission_files', COUNT(*) FROM submission_files
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'payment_transactions', COUNT(*) FROM payment_transactions
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews;

SELECT
  (SELECT COUNT(*) FROM users) + (SELECT COUNT(*) FROM roles) + (SELECT COUNT(*) FROM user_roles) +
  (SELECT COUNT(*) FROM client_profiles) + (SELECT COUNT(*) FROM freelancer_profiles) + (SELECT COUNT(*) FROM skills) +
  (SELECT COUNT(*) FROM freelancer_skills) + (SELECT COUNT(*) FROM job_categories) + (SELECT COUNT(*) FROM jobs) +
  (SELECT COUNT(*) FROM job_skills) + (SELECT COUNT(*) FROM proposals) + (SELECT COUNT(*) FROM contracts) +
  (SELECT COUNT(*) FROM milestones) + (SELECT COUNT(*) FROM submissions) + (SELECT COUNT(*) FROM submission_files) +
  (SELECT COUNT(*) FROM payments) + (SELECT COUNT(*) FROM payment_transactions) + (SELECT COUNT(*) FROM reviews) AS total_rows;
