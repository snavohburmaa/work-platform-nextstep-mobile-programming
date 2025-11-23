const express = require('express')
const cors = require('cors')
const mysql = require('mysql2')
require('dotenv').config()
const app = express()

app.use(cors())
app.use(express.json())

let pool;
if (process.env.DATABASE_URL) {
    let dbUrl = process.env.DATABASE_URL;
    
    if (dbUrl.startsWith('jdbc:')) {
        dbUrl = dbUrl.substring(5);
    }
    
    if (dbUrl.includes('<PASSWORD>')) {
        dbUrl = dbUrl.replace('<PASSWORD>', process.env.DB_PASSWORD || '');
    }
    
    const url = new URL(dbUrl);
    const sslMode = url.searchParams.get('sslMode') || process.env.DB_SSL_MODE;
    const sslParam = url.searchParams.get('ssl');
    
    let sslConfig = false;
    if (sslParam) {
        try {
            const sslObj = JSON.parse(sslParam);
            sslConfig = sslObj;
        } catch (e) {
            if (sslMode === 'VERIFY_IDENTITY' || process.env.DB_SSL === 'true') {
                sslConfig = { rejectUnauthorized: true };
            }
        }
    } else if (sslMode === 'VERIFY_IDENTITY' || process.env.DB_SSL === 'true') {
        sslConfig = { rejectUnauthorized: true };
    }
    
    pool = mysql.createPool({
        connectionLimit: 10,
        host: url.hostname,
        port: parseInt(url.port) || 3306,
        user: decodeURIComponent(url.username),
        password: decodeURIComponent(url.password),
        database: url.pathname.substring(1),
        ssl: sslConfig,
        waitForConnections: true,
        queueLimit: 0
    });
} else {
    pool = mysql.createPool({
        connectionLimit: 10,
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || '',
        database: process.env.DB_NAME || 'nextstep_db',
        port: parseInt(process.env.DB_PORT) || 3306,
        ssl: process.env.DB_SSL === 'true' ? {
            rejectUnauthorized: process.env.DB_SSL_MODE === 'VERIFY_IDENTITY'
        } : false,
        waitForConnections: true,
        queueLimit: 0
    });
}

const query = (sql, params) => {
    return new Promise((resolve, reject) => {
        pool.query(sql, params, (err, results) => {
            if (err) {
                reject(err)
            } else {
                resolve(results)
            }
        })
    })
}

app.post('/users/login', async (req, res) => {
    try {
        const { Email, PasswordHash } = req.body;
        if (!Email || !PasswordHash) {
            return res.status(400).json({ message: 'Email and password are required' });
        }
        const results = await query(
            'SELECT UserID, FullName, Email, PhoneNumber FROM users WHERE Email = ? AND PasswordHash = ?',
            [Email, PasswordHash]
        );
        if (results.length === 0) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }
        const user = results[0];
        res.json({
            message: 'Login successful',
            user: {
                id: user.UserID.toString(),
                fullName: user.FullName,
                email: user.Email,
                phone: user.PhoneNumber || '',
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Error during login' });
    }
});

app.get('/users/email/:email', async (req, res) => {
    try {
        const { email } = req.params;
        const results = await query(
            'SELECT UserID, FullName, Email, PhoneNumber FROM users WHERE Email = ?',
            [email]
        );
        if (results.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        const user = results[0];
        let firstName = user.FullName;
        let lastName = '';
        if (user.FullName.includes(' ')) {
            const nameParts = user.FullName.split(' ');
            firstName = nameParts[0] || '';
            lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : '';
        }
        res.json({
            id: user.UserID.toString(),
            firstName: firstName,
            lastName: lastName,
            fullName: user.FullName,
            email: user.Email,
            phone: user.PhoneNumber || '',
            city: '',
        });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching user' });
    }
});
app.get('/users', async (req, res) => {
    try {
        const results = await query(
            'SELECT UserID, FullName, Email FROM users'
        );
        res.json(results.map(u => {
            return {
                id: u.UserID.toString(),
                fullName: u.FullName || '',
                email: u.Email,
                city: '',
            };
        }));
    } catch (error) {
        res.status(500).json({ message: 'Error fetching users' });
    }
})
app.get('/users/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const userIdInt = parseInt(id, 10);
        if (isNaN(userIdInt)) {
            return res.status(400).json({ message: 'Invalid user ID format' });
        }
        const results = await query(
            'SELECT UserID, FullName, Email, PhoneNumber FROM users WHERE UserID = ?',
            [userIdInt]
        );
        if (results.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        const user = results[0];
        res.json({
            id: user.UserID.toString(),
            fullName: user.FullName,
            email: user.Email,
            phone: user.PhoneNumber || '',
        });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching user' });
    }
})
app.post('/users', async (req, res) => {
    try {
        const { FullName, Email, PasswordHash, PhoneNumber, City } = req.body;
        if (!FullName || !Email || !PasswordHash) {
            return res.status(400).json({ message: 'FullName, Email, and PasswordHash are required' });
        }
        const userFullName = FullName.trim();

        const existing = await query('SELECT UserID FROM users WHERE Email = ?', [Email]);
        if (existing.length > 0) {
            return res.status(409).json({ message: 'Email already registered' });
        }
        
        const results = await query(
            'INSERT INTO users (FullName, Email, PasswordHash, PhoneNumber) VALUES (?, ?, ?, ?)',
            [userFullName, Email, PasswordHash, PhoneNumber || null]
        );
       
        const newUser = await query(
            'SELECT UserID, FullName, Email, PhoneNumber FROM users WHERE UserID = ?',
            [results.insertId]
        );
        res.status(201).json({
            message: 'User successfully created',
            user: {
                id: newUser[0].UserID.toString(),
                fullName: newUser[0].FullName,
                email: newUser[0].Email,
                phone: newUser[0].PhoneNumber || '',
            }
        });
    } catch (error) {
        res.status(400).json({ message: 'Error creating user' });
    }
})

app.post('/applicants/login', async (req, res) => {
    try {
        const { Email, PasswordHash } = req.body;
        if (!Email || !PasswordHash) {
            return res.status(400).json({ message: 'Email and password are required' });
        }
        const results = await query(
            'SELECT ApplicantID, FullName, Email, PhoneNumber, City, ResumeURL FROM applicants WHERE Email = ? AND PasswordHash = ?',
            [Email, PasswordHash]
        );
        if (results.length === 0) {
            return res.status(401).json({ message: 'Invalid email or password' });
        }
        const applicant = results[0];
        res.json({
            message: 'Login successful',
            applicant: {
                id: applicant.ApplicantID.toString(),
                fullName: applicant.FullName,
                email: applicant.Email,
                phone: applicant.PhoneNumber || '',
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Error during login' });
    }
});

app.get('/applicants/email/:email', async (req, res) => {
    try {
        const { email } = req.params;
        const results = await query(
            'SELECT ApplicantID, FullName, Email, PhoneNumber FROM applicants WHERE Email = ?',
            [email]
        );
        if (results.length === 0) {
            return res.status(404).json({ message: 'Applicant not found' });
        }
        const applicant = results[0];
        res.json({
            id: applicant.ApplicantID.toString(),
            fullName: applicant.FullName,
            email: applicant.Email,
            phone: applicant.PhoneNumber || '',
        });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching applicant' });
    }
});

app.get('/applicants', async (req, res) => {
    try {
        const results = await query(
            'SELECT ApplicantID, FullName, Email, City FROM applicants'
        );
        res.json(results.map(a => ({
            id: a.ApplicantID.toString(),
            fullName: a.FullName,
            email: a.Email,
            city: a.City || '',
        })));
    } catch (error) {
        res.status(500).json({ message: 'Error fetching applicants' });
    }
})

app.get('/applicants/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const results = await query(
            'SELECT ApplicantID, FullName, Email, PhoneNumber FROM applicants WHERE ApplicantID = ?',
            [id]
        );
        if (results.length === 0) {
            return res.status(404).json({ message: 'Applicant not found' });
        }
        const applicant = results[0];
        res.json({
            id: applicant.ApplicantID.toString(),
            fullName: applicant.FullName,
            email: applicant.Email,
            phone: applicant.PhoneNumber || '',
        });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching applicant' });
    }
})

// Registration
app.post('/applicants', async (req, res) => {
    try {
        const { FullName, Email, PasswordHash, PhoneNumber, City, ResumeURL } = req.body;
        if (!FullName || !Email || !PasswordHash) {
            return res.status(400).json({ message: 'FullName, Email, and PasswordHash are required' });
        }
        const existing = await query('SELECT ApplicantID FROM applicants WHERE Email = ?', [Email]);
        if (existing.length > 0) {
            return res.status(409).json({ message: 'Email already registered' });
        }
        const results = await query(
            'INSERT INTO applicants (FullName, Email, PasswordHash, PhoneNumber, City, ResumeURL) VALUES (?, ?, ?, ?, ?, ?)',
            [FullName.trim(), Email, PasswordHash, PhoneNumber || null, City || null, ResumeURL || null]
        );
        const newApplicant = await query(
            'SELECT ApplicantID, FullName, Email, PhoneNumber FROM applicants WHERE ApplicantID = ?',
            [results.insertId]
        );
        res.status(201).json({
            message: 'Applicant successfully created',
            applicant: {
                id: newApplicant[0].ApplicantID.toString(),
                fullName: newApplicant[0].FullName,
                email: newApplicant[0].Email,
                phone: newApplicant[0].PhoneNumber || '',
            }
        });
    } catch (error) {
        res.status(400).json({ message: 'Error creating applicant' });
    }
})

// =========================================================================
// ## POSTS ROUTES (Job Postings)
// =========================================================================

// READ All Posts
app.get('/posts', async (req, res) => {
    try {
        const results = await query(
            `SELECT p.*, u.FullName, u.Email as UserEmail
             FROM posts p
             JOIN users u ON p.UserID = u.UserID
             ORDER BY p.PostedDate DESC`
        );
        
        // Format results for frontend
        const formattedPosts = await Promise.all(results.map(async (post) => {
            // Get applicant count
            const applicants = await query(
                'SELECT UserID FROM applications WHERE PostID = ?',
                [post.PostID]
            );

            return {
                id: post.PostID.toString(),
                userId: post.UserID.toString(),
                userName: post.FullName || post.UserEmail,
                userEmail: post.UserEmail,
                title: post.Title,
                company: post.CompanyName,
                location: post.Location,
                jobType: post.EmploymentType,
                description: post.Description,
                postedDate: post.PostedDate,
                salaryMin: post.SalaryMin ? parseFloat(post.SalaryMin) : null,
                salaryMax: post.SalaryMax ? parseFloat(post.SalaryMax) : null,
                salary: post.SalaryMin && post.SalaryMax 
                    ? `$${post.SalaryMin} - $${post.SalaryMax}`
                    : post.SalaryMin 
                        ? `$${post.SalaryMin}+`
                        : 'Not specified',
                createdAt: post.CreatedAt ? new Date(post.CreatedAt) : new Date(),
                applicants: applicants.map(a => a.UserID.toString()),
            };
        }));
        
        res.json(formattedPosts);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching posts' });
    }
})

//Post by ID
app.get('/posts/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const results = await query(
            `SELECT p.*, u.FullName, u.Email as UserEmail
             FROM posts p
             JOIN users u ON p.UserID = u.UserID
             WHERE p.PostID = ?`,
            [id]
        );
        if (results.length === 0) {
            return res.status(404).json({ message: 'Post not found' });
        }
        const post = results[0];
        const applicants = await query(
            'SELECT UserID FROM applications WHERE PostID = ?',
            [id]
        );
        res.json({
            id: post.PostID.toString(),
            userId: post.UserID.toString(),
            userName: post.FullName,
            userEmail: post.UserEmail,
            title: post.Title,
            company: post.CompanyName,
            location: post.Location,
            jobType: post.EmploymentType,
            description: post.Description,
            postedDate: post.PostedDate,
            salaryMin: post.SalaryMin ? parseFloat(post.SalaryMin) : null,
            salaryMax: post.SalaryMax ? parseFloat(post.SalaryMax) : null,
            salary: post.SalaryMin && post.SalaryMax 
                ? `THB${post.SalaryMin} - THB${post.SalaryMax}`
                : post.SalaryMin 
                    ? `THB${post.SalaryMin}+`
                    : 'Not specified',
            createdAt: post.CreatedAt ? new Date(post.CreatedAt) : new Date(),
                applicants: applicants.map(a => a.UserID.toString()),
        });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching post' });
    }
})

// CREATE Post
app.post('/posts', async (req, res) => {
    try {
        const { UserID, Title, CompanyName, Location, EmploymentType, Description, PostedDate, SalaryMin, SalaryMax } = req.body;  
        if (!UserID || !Title || !CompanyName || !Location || !EmploymentType || !Description) {
            return res.status(400).json({ message: 'UserID, Title, CompanyName, Location, EmploymentType, and Description are required' });
        }
        const userIdInt = parseInt(UserID, 10);
        if (isNaN(userIdInt)) {
            return res.status(400).json({ message: 'Invalid UserID format' });
        }
        const userCheck = await query('SELECT UserID FROM users WHERE UserID = ?', [userIdInt]);
        if (userCheck.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        const results = await query(
            'INSERT INTO posts (UserID, Title, CompanyName, Location, EmploymentType, Description, PostedDate, SalaryMin, SalaryMax) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [userIdInt, Title, CompanyName, Location, EmploymentType, Description, PostedDate || new Date().toISOString().split('T')[0], SalaryMin || null, SalaryMax || null]
        );
        const newPost = await query(
            `SELECT p.*, u.FullName, u.Email as UserEmail
             FROM posts p
             JOIN users u ON p.UserID = u.UserID
             WHERE p.PostID = ?`,
            [results.insertId]
        );
        
        res.status(201).json({
            message: 'Post successfully created',
            post: {
                id: newPost[0].PostID.toString(),
                userId: newPost[0].UserID.toString(),
                userName: newPost[0].FullName,
                userEmail: newPost[0].UserEmail,
                title: newPost[0].Title,
                company: newPost[0].CompanyName,
                location: newPost[0].Location,
                jobType: newPost[0].EmploymentType,
                description: newPost[0].Description,
                postedDate: newPost[0].PostedDate,
                salaryMin: newPost[0].SalaryMin ? parseFloat(newPost[0].SalaryMin) : null,
                salaryMax: newPost[0].SalaryMax ? parseFloat(newPost[0].SalaryMax) : null,
                salary: newPost[0].SalaryMin && newPost[0].SalaryMax 
                    ? `THB${newPost[0].SalaryMin} - THB${newPost[0].SalaryMax}`
                    : newPost[0].SalaryMin 
                        ? `THB${newPost[0].SalaryMin}+`
                        : 'Not specified',
                createdAt: newPost[0].CreatedAt ? new Date(newPost[0].CreatedAt) : new Date(),
                applicants: [],
            }
        });
    } catch (error) {
        res.status(400).json({ message: 'Error creating post' });
    }
})

// DELETE Post
app.delete('/posts/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const results = await query('DELETE FROM posts WHERE PostID = ?', [id]);
        
        res.json({ 
            message: 'Post deleted', 
            affectedRows: results.affectedRows 
        });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting post' });
    }
})

// Get posts by user
app.get('/posts/user/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const userIdInt = parseInt(userId, 10);
        if (isNaN(userIdInt)) {
            return res.status(400).json({ message: 'Invalid user ID format' });
        }

        const results = await query(
            `SELECT p.*, u.FullName, u.Email as UserEmail
             FROM posts p
             JOIN users u ON p.UserID = u.UserID
             WHERE p.UserID = ?
             ORDER BY p.PostedDate DESC`,
            [userIdInt]
        );
        
        const formattedPosts = await Promise.all(results.map(async (post) => {
            const applicants = await query(
                'SELECT UserID FROM applications WHERE PostID = ?',
                [post.PostID]
            );

            return {
                id: post.PostID.toString(),
                userId: post.UserID.toString(),
                userName: post.FullName || post.UserEmail,
                userEmail: post.UserEmail,
                title: post.Title,
                company: post.CompanyName,
                location: post.Location,
                jobType: post.EmploymentType,
                description: post.Description,
                postedDate: post.PostedDate,
                salaryMin: post.SalaryMin ? parseFloat(post.SalaryMin) : null,
                salaryMax: post.SalaryMax ? parseFloat(post.SalaryMax) : null,
                salary: post.SalaryMin && post.SalaryMax 
                    ? `THB${post.SalaryMin} - THB${post.SalaryMax}`
                    : post.SalaryMin 
                        ? `THB${post.SalaryMin}+`
                        : 'Not specified',
                createdAt: post.CreatedAt ? new Date(post.CreatedAt) : new Date(),
                applicants: applicants.map(a => a.UserID.toString()),
            };
        }));
        res.json(formattedPosts);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching posts' });
    }
});

// Apply
app.post('/apply', async (req, res) => {
    try {
        const { UserID, PostID, Message } = req.body; 
        if (!UserID || !PostID) {
            return res.status(400).json({ message: 'UserID and PostID are required' });
        }
        const userIdInt = parseInt(UserID, 10);
        const postIdInt = parseInt(PostID, 10);
        
        if (isNaN(userIdInt) || isNaN(postIdInt)) {
            return res.status(400).json({ message: 'Invalid UserID or PostID format' });
        }
        const userCheck = await query('SELECT UserID, FullName, Email FROM users WHERE UserID = ?', [userIdInt]);
        if (userCheck.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        const existing = await query(
            'SELECT ApplicationID FROM applications WHERE UserID = ? AND PostID = ?',
            [userIdInt, postIdInt]
        );

        if (existing.length > 0) {
            return res.status(409).json({ message: 'Already applied for this job.' });
        }
        
        const postCheck = await query('SELECT PostID FROM posts WHERE PostID = ?', [postIdInt]);
        if (postCheck.length === 0) {
            return res.status(404).json({ message: 'Job post not found' });
        }
        
        const results = await query(
            'INSERT INTO applications (UserID, PostID, Message) VALUES (?, ?, ?)',
            [userIdInt, postIdInt, Message || null]
        );
        const application = await query(
            `SELECT a.ApplicationID, a.UserID, a.PostID, a.Message, a.DateApplied,
                    u.FullName, u.Email,
                    p.Title as PostTitle
             FROM applications a
             JOIN users u ON a.UserID = u.UserID
             JOIN posts p ON a.PostID = p.PostID
             WHERE a.ApplicationID = ?`,
            [results.insertId]
        );

        if (application.length === 0) {
            return res.status(500).json({ message: 'Failed to retrieve created application' });
        }

        res.status(201).json({
            message: 'Application submitted successfully',
            application: {
                id: application[0].ApplicationID.toString(),
                applicantId: application[0].UserID.toString(),
                postId: application[0].PostID.toString(),
                jobTitle: application[0].PostTitle,
                applicantName: application[0].FullName,
                applicantEmail: application[0].Email,
                message: application[0].Message || '',
                appliedAt: application[0].DateApplied,
            }
        });
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ message: 'Already applied for this job.' });
        }
        res.status(400).json({ message: 'Error submitting application' });
    }
})

// Get all applications
app.get('/applications', async (req, res) => {
    try {
        const results = await query(
            `SELECT a.ApplicationID, a.UserID, a.PostID, a.Message, a.DateApplied,
                    p.Title as PostTitle,
                    u.FullName, u.Email
             FROM applications a
             JOIN posts p ON a.PostID = p.PostID
             JOIN users u ON a.UserID = u.UserID
             ORDER BY a.DateApplied DESC`
        );

        const applications = results.map(app => ({
            id: app.ApplicationID.toString(),
            applicantId: app.UserID.toString(),
            postId: app.PostID.toString(),
            jobTitle: app.PostTitle,
            applicantName: app.FullName,
            applicantEmail: app.Email,
            message: app.Message || '',
            appliedAt: app.DateApplied,
        }));

        res.json(applications);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching applications' });
    }
});

// Get applications by applicant
app.get('/applications/applicant/:applicantId', async (req, res) => {
    const userId = req.params.applicantId;
    const userIdInt = parseInt(userId, 10);
    if (isNaN(userIdInt)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
    }
    try {
        const results = await query(
            `SELECT a.ApplicationID, a.UserID, a.PostID, a.Message, a.DateApplied,
                    p.Title as PostTitle, p.CompanyName, p.Location, p.EmploymentType,
                    u.FullName, u.Email
             FROM applications a
             JOIN posts p ON a.PostID = p.PostID
             JOIN users u ON a.UserID = u.UserID
             WHERE a.UserID = ?
             ORDER BY a.DateApplied DESC`,
            [userIdInt]
        );
        const applications = results.map(app => ({
            id: app.ApplicationID.toString(),
            applicantId: app.UserID.toString(),
            postId: app.PostID.toString(),
            jobTitle: app.PostTitle,
            applicantName: app.FullName,
            applicantEmail: app.Email,
            message: app.Message || '',
            appliedAt: app.DateApplied,
        }));
        res.json(applications);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching applications' });
    }
});

// Get applications by user
app.get('/applications/user/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const userIdInt = parseInt(userId, 10);
        if (isNaN(userIdInt)) {
            return res.status(400).json({ message: 'Invalid user ID format' });
        }
        const results = await query(
            `SELECT a.ApplicationID, a.UserID, a.PostID, a.Message, a.DateApplied,
                    p.Title as PostTitle, p.CompanyName, p.Location, p.EmploymentType,
                    u.FullName, u.Email
             FROM applications a
             JOIN posts p ON a.PostID = p.PostID
             JOIN users u ON a.UserID = u.UserID
             WHERE a.UserID = ?
             ORDER BY a.DateApplied DESC`,
            [userIdInt]
        );
        const applications = results.map(app => ({
            id: app.ApplicationID.toString(),
            applicantId: app.UserID.toString(),
            postId: app.PostID.toString(),
            jobTitle: app.PostTitle,
            applicantName: app.FullName,
            applicantEmail: app.Email,
            message: app.Message || '',
            appliedAt: app.DateApplied,
        }));
        res.json(applications);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching applications' });
    }
});

// Get applications by post
app.get('/applications/post/:postId', async (req, res) => {
    try {
        const { postId } = req.params;
        const postIdInt = parseInt(postId, 10);
        if (isNaN(postIdInt)) {
            return res.status(400).json({ message: 'Invalid post ID format' });
        }
        const results = await query(
            `SELECT a.ApplicationID, a.UserID, a.PostID, a.Message, a.DateApplied,
                    p.Title as PostTitle,
                    u.FullName, u.Email
             FROM applications a
             JOIN posts p ON a.PostID = p.PostID
             JOIN users u ON a.UserID = u.UserID
             WHERE a.PostID = ?
             ORDER BY a.DateApplied DESC`,
            [postIdInt]
        );
        const applications = results.map(app => ({
            id: app.ApplicationID.toString(),
            applicantId: app.UserID.toString(),
            postId: app.PostID.toString(),
            jobTitle: app.PostTitle,
            applicantName: app.FullName,
            applicantEmail: app.Email,
            message: app.Message || '',
            appliedAt: app.DateApplied,
        }));
        res.json(applications);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching applications' });
    }
});

// apply check 
app.get('/applications/check/:postId/:userId', async (req, res) => {
    try {
        const { postId, userId } = req.params;
        const results = await query(
            'SELECT * FROM applications WHERE PostID = ? AND UserID = ?',
            [postId, userId]
        );
        res.json({
            hasApplied: results.length > 0,
            application: results.length > 0 ? {
                id: results[0].ApplicationID.toString(),
                applicantId: results[0].UserID.toString(),
                postId: results[0].PostID.toString(),
                message: results[0].Message || '',
                appliedAt: results[0].DateApplied,
            } : null
        });
    } catch (error) {
        res.status(500).json({ message: 'Error checking application' });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {})

module.exports = app
