-- NextStep Job Platform Database Schema
-- MySQL Database for Job Application Platform

-- Create database
CREATE DATABASE IF NOT EXISTS nextstep_db;
USE nextstep_db;

-- Users Table (for recruiters/posters)
CREATE TABLE IF NOT EXISTS users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    FullName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    PhoneNumber VARCHAR(20),
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Posts Table (Job Postings)
CREATE TABLE IF NOT EXISTS posts (
    PostID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    Title VARCHAR(100) NOT NULL,
    CompanyName VARCHAR(100) NOT NULL,
    Location VARCHAR(100) NOT NULL,
    EmploymentType ENUM('Full-time', 'Part-time', 'Contract', 'Internship') NOT NULL,
    Description TEXT NOT NULL,
    SalaryMin DECIMAL(10, 2),
    SalaryMax DECIMAL(10, 2),
    PostedDate DATE NOT NULL,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (UserID) REFERENCES users(UserID) ON DELETE CASCADE
);

-- Applications Table (Job Applications)
CREATE TABLE IF NOT EXISTS applications (
    ApplicationID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    PostID INT NOT NULL,
    Message TEXT,
    DateApplied DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (UserID) REFERENCES users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (PostID) REFERENCES posts(PostID) ON DELETE CASCADE,
    
    -- Prevent duplicate applications
    UNIQUE KEY unique_application (UserID, PostID)
);

-- Indexes for better performance
CREATE INDEX idx_user_email ON users(Email);
CREATE INDEX idx_application_user ON applications(UserID);
CREATE INDEX idx_application_post ON applications(PostID);
CREATE INDEX idx_post_user ON posts(UserID);
CREATE INDEX idx_post_date ON posts(PostedDate);
