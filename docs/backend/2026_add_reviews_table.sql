-- ============================================================
-- Migration: add the Reviews table to memberaccount_db
-- Run once against the memberaccount database (local XAMPP MySQL,
-- and the deployed Render MySQL) before deploying reviews_api.php.
--
--   mysql -u root memberaccount_db < 2026_add_reviews_table.sql
-- ============================================================

CREATE TABLE IF NOT EXISTS Reviews (
    ReviewID   INT AUTO_INCREMENT PRIMARY KEY,
    MemberID   INT          NOT NULL,
    Rating     TINYINT      NOT NULL,          -- 1..5
    Comment    VARCHAR(600) NOT NULL,
    CreatedAt  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status     ENUM('pending','approved','hidden') NOT NULL DEFAULT 'pending',
    CONSTRAINT fk_reviews_member
        FOREIGN KEY (MemberID) REFERENCES Members(MemberID) ON DELETE CASCADE,
    CONSTRAINT chk_reviews_rating CHECK (Rating BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_reviews_status_created ON Reviews (Status, CreatedAt);

-- The reviewer's name is NOT stored here — it is joined from Members at
-- read time, so a member renaming themselves updates their reviews too.
--
-- New reviews land as 'pending'. Approve them from the admin side, e.g.:
--   UPDATE Reviews SET Status = 'approved' WHERE ReviewID = ?;
-- (or change reviews_api.php's default insert Status to 'approved' if you
--  want reviews to publish immediately without moderation.)
