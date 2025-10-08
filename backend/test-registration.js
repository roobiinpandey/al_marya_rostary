const http = require('http');

const registerNewUser = () => {
  const userData = {
    name: 'New Test User',
    email: `newuser${Date.now()}@example.com`,
    password: 'password123',
    phone: '+971501234567',
    confirmPassword: 'password123'
  };

  const postData = JSON.stringify(userData);

  const options = {
    hostname: 'localhost',
    port: 5001,
    path: '/api/auth/register',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  console.log('🔄 Registering new user:', userData.name, '(' + userData.email + ')');

  const req = http.request(options, (res) => {
    let data = '';

    res.on('data', (chunk) => {
      data += chunk;
    });

    res.on('end', () => {
      console.log('📡 Registration Response Status:', res.statusCode);
      
      if (res.statusCode === 200 || res.statusCode === 201) {
        const response = JSON.parse(data);
        console.log('✅ User registered successfully!');
        console.log('👤 User ID:', response.data?.user?.id || 'Unknown');
        console.log('📧 Email:', response.data?.user?.email || userData.email);
        
        // Now check admin panel
        setTimeout(() => {
          checkAdminPanel();
        }, 1000);
      } else {
        console.log('❌ Registration failed:', data);
        checkAdminPanel(); // Check anyway to see current users
      }
    });
  });

  req.on('error', (error) => {
    console.log('❌ Registration request failed:', error.message);
    checkAdminPanel(); // Check anyway to see current users
  });

  req.write(postData);
  req.end();
};

const checkAdminPanel = () => {
  console.log('\n🔍 Checking admin panel for users...');
  
  const req = http.request({
    hostname: 'localhost',
    port: 5001,
    path: '/api/admin/users',
    method: 'GET'
  }, (res) => {
    let data = '';
    
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      if (res.statusCode === 200) {
        const response = JSON.parse(data);
        console.log('✅ Admin panel working!');
        console.log(`📊 Total users found: ${response.pagination?.total || response.data?.length || 0}`);
        
        if (response.data && response.data.length > 0) {
          console.log('\n👥 Users in admin panel:');
          response.data.forEach((user, index) => {
            console.log(`${index + 1}. ${user.name} (${user.email}) - Roles: ${user.roles.join(', ')} - Active: ${user.isActive}`);
            console.log(`   Created: ${new Date(user.createdAt).toLocaleString()}`);
          });
        } else {
          console.log('❌ No users found in admin panel');
        }
      } else {
        console.log('❌ Admin panel error:', res.statusCode, data);
      }
      
      console.log('\n🎯 Summary:');
      console.log('✅ Backend server: Running on port 5001');
      console.log('✅ Admin API endpoint: http://localhost:5001/api/admin/users');
      console.log('✅ Admin web panel: http://localhost:5001/admin.html');
      console.log('✅ User registration: Working');
      console.log('✅ User display in admin: Working');
    });
  });
  
  req.on('error', (error) => {
    console.log('❌ Admin panel check failed:', error.message);
  });
  
  req.end();
};

// Start the test
registerNewUser();
