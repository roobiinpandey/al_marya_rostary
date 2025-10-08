# Qahwat Al Emarat Admin Web Access

## How to Access Admin Panel

The admin functionality has been moved from the mobile app to a dedicated web interface for better accessibility and management.

### Web Admin Panel

1. **Location**: The admin web pages are located in the `web/` directory:
   - `web/index.html` - Main admin portal landing page
   - `web/admin.html` - Admin login and dashboard

2. **Access Methods**:

   **Option A: Local Development Server**
   ```bash
   # Navigate to the web directory
   cd web

   # Serve the files using a local server (Python)
   python -m http.server 8000

   # Or using Node.js (if you have http-server installed)
   npx http-server

   # Then open http://localhost:8000 in your browser
   ```

   **Option B: Direct File Access**
   - Open `web/index.html` directly in your web browser
   - Click "Access Admin Panel" to go to the login page

3. **Default Login Credentials**:
   - **Username**: `admin`
   - **Password**: `qahwat2024`

### Features Available

- **Dashboard**: Overview of business metrics (orders, revenue, products, customers)
- **Quick Actions**: Buttons for orders, products, and analytics (placeholders for now)
- **Responsive Design**: Works on desktop and mobile browsers

### Security Notes

- This is a basic implementation with client-side authentication
- For production use, implement proper server-side authentication
- Change the default password before deploying
- Consider adding HTTPS for secure access

### Future Enhancements

- Backend API integration
- Real-time data updates
- Advanced analytics and reporting
- User management
- Order processing workflow
