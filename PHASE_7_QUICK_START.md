# 🚀 PHASE 7: QUICK START CHECKLIST

**Start Date:** November 11, 2025  
**Your Current Status:** ✅ E2E Tests Passing - Ready to Begin!

---

## ✅ WEEK 1: CI/CD SETUP - START HERE

### 📋 Pre-Flight Checklist (Do This First!)

```bash
# 1. Create a new branch for Phase 7 work
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"
git checkout -b phase-7-production
git push -u origin phase-7-production

# 2. Backup your current database
mongodump --uri="YOUR_MONGODB_URI" --out=./backups/pre-phase7-backup

# 3. Create test environment file
cp backend/.env backend/.env.test
# Edit .env.test with test database credentials
```

---

## 🎯 DAY 1: MONDAY (GitHub Actions Setup)

### Morning (4 hours)

**Task 1: Create GitHub Actions Directory**
```bash
mkdir -p .github/workflows
```

**Task 2: Create Backend CI Workflow**

Create: `.github/workflows/backend-ci.yml`

```yaml
name: Backend CI

on:
  push:
    branches: [ main, develop, phase-7-* ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mongodb:
        image: mongo:7.0
        ports:
          - 27017:27017
        env:
          MONGO_INITDB_ROOT_USERNAME: test
          MONGO_INITDB_ROOT_PASSWORD: test123
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
        cache: 'npm'
        cache-dependency-path: backend/package-lock.json
    
    - name: Install dependencies
      working-directory: backend
      run: npm ci
    
    - name: Create test env file
      working-directory: backend
      run: |
        echo "NODE_ENV=test" > .env.test
        echo "MONGODB_URI=mongodb://test:test123@localhost:27017/test?authSource=admin" >> .env.test
        echo "JWT_SECRET=test-jwt-secret-key-12345" >> .env.test
        echo "BASE_URL=http://localhost:5001" >> .env.test
    
    - name: Wait for MongoDB
      run: |
        timeout 30 bash -c 'until nc -z localhost 27017; do sleep 1; done'
    
    - name: Run E2E Tests
      working-directory: backend
      run: |
        npm run test:e2e:setup
        npm run test:e2e
      env:
        NODE_ENV: test
    
    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: backend/test-results/
```

**Task 3: Test the workflow**
```bash
git add .github/workflows/backend-ci.yml
git commit -m "Add GitHub Actions CI workflow"
git push
```

**✅ Success Criteria:**
- GitHub Actions workflow file created
- Workflow runs on push
- MongoDB service starts
- Tests execute (even if they fail initially)

### Afternoon (4 hours)

**Task 4: Fix any CI failures**
- Review GitHub Actions logs
- Fix environment issues
- Ensure tests pass in CI

**Task 5: Add Linting**

Create: `.github/workflows/lint.yml`

```yaml
name: Lint

on: [push, pull_request]

jobs:
  eslint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-node@v3
      with:
        node-version: '20'
    - name: Install dependencies
      working-directory: backend
      run: npm ci
    - name: Run ESLint
      working-directory: backend
      run: npx eslint . --ext .js --max-warnings 0 || true
```

**✅ End of Day 1:**
- ✅ GitHub Actions CI working
- ✅ E2E tests running in CI
- ✅ Linting workflow added

---

## 🎯 DAY 2: TUESDAY (Test Enhancement)

### Morning (4 hours)

**Task 1: Install Testing Framework**
```bash
cd backend
npm install --save-dev jest supertest @jest/globals
```

**Task 2: Create Jest Configuration**

Create: `backend/jest.config.js`

```javascript
module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'routes/**/*.js',
    'controllers/**/*.js',
    'services/**/*.js',
    '!**/node_modules/**'
  ],
  testMatch: [
    '**/tests/**/*.test.js',
    '**/tests/**/*.spec.js'
  ],
  setupFilesAfterEnv: ['<rootDir>/tests/setup/jest.setup.js']
};
```

**Task 3: Create Test Setup File**

Create: `backend/tests/setup/jest.setup.js`

```javascript
const mongoose = require('mongoose');

// Set test timeout
jest.setTimeout(30000);

// Setup test database connection
beforeAll(async () => {
  const mongoUri = process.env.MONGODB_TEST_URI || 
                   'mongodb://test:test123@localhost:27017/test?authSource=admin';
  await mongoose.connect(mongoUri);
});

// Clean up after all tests
afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
});

// Clear collections after each test
afterEach(async () => {
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany();
  }
});
```

### Afternoon (4 hours)

**Task 4: Create Integration Tests**

Create: `backend/tests/integration/auth.test.js`

```javascript
const request = require('supertest');
const app = require('../../server');

describe('Authentication API', () => {
  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'Test1234!',
          phone: '+971501234567'
        });
      
      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('token');
    });
    
    it('should reject duplicate email', async () => {
      // Create first user
      await request(app)
        .post('/api/auth/register')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'Test1234!',
          phone: '+971501234567'
        });
      
      // Try to create duplicate
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'Test User 2',
          email: 'test@example.com',
          password: 'Test1234!',
          phone: '+971501234568'
        });
      
      expect(response.status).toBe(400);
    });
  });
  
  describe('POST /api/auth/login', () => {
    it('should login existing user', async () => {
      // Register user first
      await request(app)
        .post('/api/auth/register')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'Test1234!',
          phone: '+971501234567'
        });
      
      // Login
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'Test1234!'
        });
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('token');
    });
  });
});
```

**Task 5: Add npm test script**

Update `backend/package.json`:
```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:e2e": "BASE_URL=http://127.0.0.1:5001 node test-e2e-complete-flow.js",
    "test:e2e:setup": "BASE_URL=http://127.0.0.1:5001 node setup-e2e-test.js"
  }
}
```

**✅ End of Day 2:**
- ✅ Jest configured
- ✅ Integration tests created
- ✅ Tests passing locally

---

## 🎯 DAY 3: WEDNESDAY (E2E Test Automation)

### Morning (4 hours)

**Task 1: Create E2E Workflow**

Create: `.github/workflows/e2e-tests.yml`

```yaml
name: E2E Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight

jobs:
  e2e:
    runs-on: ubuntu-latest
    
    services:
      mongodb:
        image: mongo:7.0
        ports:
          - 27017:27017
        env:
          MONGO_INITDB_ROOT_USERNAME: test
          MONGO_INITDB_ROOT_PASSWORD: test123
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install dependencies
      working-directory: backend
      run: npm ci
    
    - name: Create test environment
      working-directory: backend
      run: |
        cp .env.example .env
        echo "MONGODB_URI=mongodb://test:test123@localhost:27017/test?authSource=admin" >> .env
        echo "JWT_SECRET=test-jwt-secret-key-12345" >> .env
    
    - name: Start server in background
      working-directory: backend
      run: |
        npm start &
        sleep 10
      env:
        NODE_ENV: test
    
    - name: Setup test data
      working-directory: backend
      run: npm run test:e2e:setup
    
    - name: Run E2E tests
      working-directory: backend
      run: npm run test:e2e
    
    - name: Upload E2E test results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: e2e-results
        path: backend/e2e-results.json
```

### Afternoon (4 hours)

**Task 2: Add Test Reporting**

Install reporting tools:
```bash
cd backend
npm install --save-dev mochawesome mochawesome-merge mochawesome-report-generator
```

**Task 3: Create Test Reporter**

Update `backend/test-e2e-complete-flow.js` to generate JSON report:

```javascript
// Add at the end of runE2ETest function
const fs = require('fs');

const testReport = {
  timestamp: new Date().toISOString(),
  duration: ((Date.now() - startTime) / 1000).toFixed(2) + 's',
  orderNumber: testData.orderNumber,
  steps: {
    customerOrder: passed >= 1,
    databaseVerify: passed >= 2,
    staffProcessing: passed >= 3,
    driverDelivery: passed >= 4,
    customerHistory: passed >= 5,
    finalValidation: passed >= 6
  },
  assertions: {
    passed,
    failed,
    total: passed + failed
  }
};

fs.writeFileSync('e2e-results.json', JSON.stringify(testReport, null, 2));
```

**✅ End of Day 3:**
- ✅ E2E tests automated in CI
- ✅ Test reporting implemented
- ✅ Daily scheduled E2E tests

---

## 🎯 DAY 4: THURSDAY (Staging Environment)

### Full Day (8 hours)

**Task 1: Create Staging on Render.com**

1. Go to https://render.com/
2. Click "New +" → "Web Service"
3. Connect your GitHub repo
4. Configure:
   ```
   Name: al-marya-staging
   Branch: develop
   Runtime: Node
   Build Command: cd backend && npm install
   Start Command: cd backend && npm start
   ```

**Task 2: Configure Staging Environment Variables**

Add in Render dashboard:
```
NODE_ENV=staging
MONGODB_URI=[Create new staging MongoDB]
JWT_SECRET=[Generate new secret]
STRIPE_SECRET_KEY=[Use Stripe test key]
FIREBASE_ADMIN_SDK=[Copy from production]
```

**Task 3: Create Staging Database**

1. Go to MongoDB Atlas
2. Create new cluster: "al-marya-staging"
3. Create database user
4. Get connection string
5. Update Render environment

**Task 4: Test Staging Deployment**

```bash
# Push to develop branch
git checkout develop
git merge phase-7-production
git push origin develop

# Watch deployment in Render dashboard
# Test staging URL once deployed
```

**✅ End of Day 4:**
- ✅ Staging environment live
- ✅ Auto-deploys from develop branch
- ✅ Staging database configured

---

## 🎯 DAY 5: FRIDAY (Production Pipeline)

### Morning (4 hours)

**Task 1: Create Production Deployment Workflow**

Create: `.github/workflows/deploy-production.yml`

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]
    paths:
      - 'backend/**'
  workflow_dispatch:  # Manual trigger

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://your-app.onrender.com
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Render
      uses: johnbeynon/render-deploy-action@v0.0.8
      with:
        service-id: ${{ secrets.RENDER_SERVICE_ID }}
        api-key: ${{ secrets.RENDER_API_KEY }}
    
    - name: Wait for deployment
      run: sleep 60
    
    - name: Health check
      run: |
        curl -f https://your-app.onrender.com/health || exit 1
    
    - name: Notify team
      if: always()
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        text: 'Production deployment ${{ job.status }}'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Afternoon (4 hours)

**Task 2: Setup GitHub Environments**

1. Go to repo Settings → Environments
2. Create "production" environment
3. Add protection rules:
   - ✅ Required reviewers (yourself)
   - ✅ Wait 5 minutes before deployment
4. Add secrets:
   - `RENDER_SERVICE_ID`
   - `RENDER_API_KEY`

**Task 3: Document Deployment Process**

Create: `docs/DEPLOYMENT.md`
```markdown
# Deployment Process

## Staging
- Auto-deploys from `develop` branch
- URL: https://al-marya-staging.onrender.com

## Production
- Manual approval required
- Deploys from `main` branch
- URL: https://almaryarostery.onrender.com

## Process
1. Merge feature branch to `develop`
2. Test on staging
3. Create PR from `develop` to `main`
4. After approval, merge triggers production deployment
5. Review and approve in GitHub Actions
6. Monitor deployment health check
```

**✅ End of Week 1:**
- ✅ Complete CI/CD pipeline
- ✅ Automated testing
- ✅ Staging + Production deployment
- ✅ Ready for Week 2 (Production go-live)

---

## 📊 WEEK 1 SUCCESS METRICS

At the end of Week 1, you should have:

✅ **CI/CD Infrastructure:**
- [ ] GitHub Actions workflows running
- [ ] E2E tests passing in CI
- [ ] Test coverage >50%
- [ ] Lint checks passing

✅ **Environments:**
- [ ] Staging environment deployed
- [ ] Production deployment pipeline ready
- [ ] Environment variables configured
- [ ] Database backups automated

✅ **Quality Gates:**
- [ ] All tests must pass before merge
- [ ] Manual approval for production
- [ ] Health checks after deployment
- [ ] Rollback procedure documented

---

## 🚨 TROUBLESHOOTING

### Issue: GitHub Actions failing

**Solution:**
```bash
# Check logs in GitHub Actions tab
# Common fixes:
- Ensure MongoDB service is healthy
- Check environment variables
- Verify Node version matches (20.x)
- Increase timeout if tests are slow
```

### Issue: Staging deployment failing

**Solution:**
```bash
# Check Render logs
# Common fixes:
- Verify build command path
- Check environment variables
- Ensure MongoDB connection string is correct
- Review port configuration (Render assigns PORT)
```

### Issue: Tests timing out in CI

**Solution:**
```yaml
# Increase timeout in workflow
- name: Run E2E tests
  run: npm run test:e2e
  timeout-minutes: 15  # Add this
```

---

## 📞 NEED HELP?

**Resources:**
- GitHub Actions Docs: https://docs.github.com/actions
- Render Docs: https://render.com/docs
- Jest Docs: https://jestjs.io/docs/getting-started

**Quick Commands:**
```bash
# Run tests locally
cd backend && npm test

# Run E2E tests
npm run test:e2e

# Check CI status
gh run list

# View workflow logs
gh run view [run-id] --log
```

---

## ✅ READY TO START?

```bash
# Let's begin! Run these commands:
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"
git checkout -b phase-7-production
mkdir -p .github/workflows
# Now create the first workflow file from Day 1 tasks above
```

**Good luck! 🚀**

**Questions?** Refer to PHASE_7_PRODUCTION_DEPLOYMENT_PLAN.md for detailed information.
