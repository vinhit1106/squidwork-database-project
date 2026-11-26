
CREATE TABLE IF NOT EXISTS users (
  id BIGINT NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS roles (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL,
  description VARCHAR(255),
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_roles (
  user_id BIGINT NOT NULL,
  role_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (user_id, role_id),
  KEY idx_user_roles_role (role_id),
  CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS client_profiles (
  user_id BIGINT NOT NULL,
  company_name VARCHAR(150),
  description TEXT,
  country_code CHAR(2),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (user_id),
  CONSTRAINT fk_client_profiles_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS freelancer_profiles (
  user_id BIGINT NOT NULL,
  headline VARCHAR(200),
  bio TEXT,
  hourly_rate DECIMAL(12,2),
  currency_code CHAR(3),
  experience_years INT,
  portfolio_url VARCHAR(500),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (user_id),
  CONSTRAINT fk_freelancer_profiles_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS skills (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_skills_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS freelancer_skills (
  freelancer_user_id BIGINT NOT NULL,
  skill_id BIGINT NOT NULL,
  proficiency_level VARCHAR(30),
  years_experience DECIMAL(4,1),
  PRIMARY KEY (freelancer_user_id, skill_id),
  KEY idx_freelancer_skills_skill (skill_id),
  CONSTRAINT fk_freelancer_skills_user FOREIGN KEY (freelancer_user_id) REFERENCES freelancer_profiles(user_id),
  CONSTRAINT fk_freelancer_skills_skill FOREIGN KEY (skill_id) REFERENCES skills(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS job_categories (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_job_categories_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS jobs (
  id BIGINT NOT NULL AUTO_INCREMENT,
  client_user_id BIGINT NOT NULL,
  category_id BIGINT NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  budget_type VARCHAR(20) NOT NULL,
  budget_min DECIMAL(14,2) NOT NULL,
  budget_max DECIMAL(14,2) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
  deadline DATE,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_jobs_id_client (id, client_user_id),
  KEY idx_jobs_status_created (status, created_at),
  KEY idx_jobs_category_status (category_id, status),
  KEY idx_jobs_client_created (client_user_id, created_at),
  CONSTRAINT fk_jobs_client FOREIGN KEY (client_user_id) REFERENCES client_profiles(user_id),
  CONSTRAINT fk_jobs_category FOREIGN KEY (category_id) REFERENCES job_categories(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS job_skills (
  job_id BIGINT NOT NULL,
  skill_id BIGINT NOT NULL,
  PRIMARY KEY (job_id, skill_id),
  KEY idx_job_skills_skill (skill_id),
  CONSTRAINT fk_job_skills_job FOREIGN KEY (job_id) REFERENCES jobs(id),
  CONSTRAINT fk_job_skills_skill FOREIGN KEY (skill_id) REFERENCES skills(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS proposals (
  id BIGINT NOT NULL AUTO_INCREMENT,
  job_id BIGINT NOT NULL,
  freelancer_user_id BIGINT NOT NULL,
  cover_letter TEXT NOT NULL,
  proposed_amount DECIMAL(14,2) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  proposed_duration_days INT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_proposals_job_freelancer (job_id, freelancer_user_id),
  UNIQUE KEY uq_proposals_id_job_freelancer (id, job_id, freelancer_user_id),
  KEY idx_proposals_job_status (job_id, status, created_at),
  KEY idx_proposals_freelancer (freelancer_user_id, created_at),
  CONSTRAINT fk_proposals_job FOREIGN KEY (job_id) REFERENCES jobs(id),
  CONSTRAINT fk_proposals_freelancer FOREIGN KEY (freelancer_user_id) REFERENCES freelancer_profiles(user_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS contracts (
  id BIGINT NOT NULL AUTO_INCREMENT,
  proposal_id BIGINT NOT NULL,
  job_id BIGINT NOT NULL,
  client_user_id BIGINT NOT NULL,
  freelancer_user_id BIGINT NOT NULL,
  title VARCHAR(200) NOT NULL,
  terms TEXT,
  total_amount DECIMAL(14,2) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  start_at TIMESTAMP NULL,
  end_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_contracts_proposal (proposal_id),
  UNIQUE KEY uq_contracts_id_client_freelancer (id, client_user_id, freelancer_user_id),
  UNIQUE KEY uq_contracts_id_client (id, client_user_id),
  UNIQUE KEY uq_contracts_id_freelancer (id, freelancer_user_id),
  CONSTRAINT fk_contracts_proposal FOREIGN KEY (proposal_id, job_id, freelancer_user_id) REFERENCES proposals(id, job_id, freelancer_user_id),
  CONSTRAINT fk_contracts_job_client FOREIGN KEY (job_id, client_user_id) REFERENCES jobs(id, client_user_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS milestones (
  id BIGINT NOT NULL AUTO_INCREMENT,
  contract_id BIGINT NOT NULL,
  sequence_no INT NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  amount DECIMAL(14,2) NOT NULL,
  due_at TIMESTAMP NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
  submitted_at TIMESTAMP NULL,
  completed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_milestones_contract_sequence (contract_id, sequence_no),
  UNIQUE KEY uq_milestones_id_contract (id, contract_id),
  CONSTRAINT fk_milestones_contract FOREIGN KEY (contract_id) REFERENCES contracts(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS submissions (
  id BIGINT NOT NULL AUTO_INCREMENT,
  milestone_id BIGINT NOT NULL,
  contract_id BIGINT NOT NULL,
  version INT NOT NULL DEFAULT 1,
  submitted_by_user_id BIGINT NOT NULL,
  note TEXT,
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
  reviewer_user_id BIGINT,
  review_feedback TEXT,
  reviewed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_submissions_milestone_version (milestone_id, version),
  KEY idx_submissions_milestone_status (milestone_id, status),
  KEY idx_submissions_contract_submitter (contract_id, submitted_by_user_id),
  KEY idx_submissions_contract_reviewer (contract_id, reviewer_user_id),
  CONSTRAINT fk_submissions_milestone FOREIGN KEY (milestone_id, contract_id) REFERENCES milestones(id, contract_id),
  CONSTRAINT fk_submissions_submitter FOREIGN KEY (contract_id, submitted_by_user_id) REFERENCES contracts(id, freelancer_user_id),
  CONSTRAINT fk_submissions_reviewer FOREIGN KEY (contract_id, reviewer_user_id) REFERENCES contracts(id, client_user_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS submission_files (
  id BIGINT NOT NULL AUTO_INCREMENT,
  submission_id BIGINT NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_url VARCHAR(1000) NOT NULL,
  file_type VARCHAR(100),
  file_size BIGINT,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  KEY idx_submission_files_submission (submission_id),
  CONSTRAINT fk_submission_files_submission FOREIGN KEY (submission_id) REFERENCES submissions(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
  id BIGINT NOT NULL AUTO_INCREMENT,
  milestone_id BIGINT NOT NULL,
  contract_id BIGINT NOT NULL,
  client_user_id BIGINT NOT NULL,
  freelancer_user_id BIGINT NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  currency_code CHAR(3) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_payments_milestone (milestone_id),
  CONSTRAINT fk_payments_contract FOREIGN KEY (contract_id, client_user_id, freelancer_user_id) REFERENCES contracts(id, client_user_id, freelancer_user_id),
  CONSTRAINT fk_payments_milestone FOREIGN KEY (milestone_id, contract_id) REFERENCES milestones(id, contract_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payment_transactions (
  id BIGINT NOT NULL AUTO_INCREMENT,
  payment_id BIGINT NOT NULL,
  transaction_type VARCHAR(20) NOT NULL,
  provider VARCHAR(50) NOT NULL,
  provider_reference VARCHAR(255),
  idempotency_key VARCHAR(100) NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'INITIATED',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_payment_transactions_idempotency (idempotency_key),
  UNIQUE KEY uq_payment_transactions_provider_reference (provider, provider_reference),
  KEY idx_payment_transactions_payment (payment_id, created_at),
  CONSTRAINT fk_payment_transactions_payment FOREIGN KEY (payment_id) REFERENCES payments(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reviews (
  id BIGINT NOT NULL AUTO_INCREMENT,
  contract_id BIGINT NOT NULL,
  reviewer_user_id BIGINT NOT NULL,
  reviewee_user_id BIGINT NOT NULL,
  rating INT NOT NULL,
  comment TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_reviews_contract_reviewer (contract_id, reviewer_user_id),
  KEY idx_reviews_reviewee_created (reviewee_user_id, created_at),
  CONSTRAINT fk_reviews_contract FOREIGN KEY (contract_id) REFERENCES contracts(id),
  CONSTRAINT fk_reviews_reviewer FOREIGN KEY (reviewer_user_id) REFERENCES users(id),
  CONSTRAINT fk_reviews_reviewee FOREIGN KEY (reviewee_user_id) REFERENCES users(id),
  CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;
