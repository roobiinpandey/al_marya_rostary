const fetch = require('node-fetch');

async function testProductionLogin() {
    try {
        console.log('🧪 Testing Production Admin Login...');
        
        const response = await fetch('http://localhost:5001/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: 'almarya@admin',
                password: 'almaryaadmin2020'
            })
        });

        const data = await response.json();

        console.log('📋 Response Status:', response.status);
        console.log('📄 Response Data:', JSON.stringify(data, null, 2));

        if (response.ok && data.success) {
            console.log('✅ Login Successful!');
            if (data.user) {
                console.log('👤 User:', data.user.name);
                console.log('📧 Email:', data.user.email);
                console.log('🔑 Role:', data.user.roles);
            }
            console.log('🎯 Token received:', !!(data.data && data.data.token));
            console.log('🚀 Production admin login is working correctly!');
        } else {
            console.log('❌ Login Failed:', data.message || 'Unknown error');
        }

    } catch (error) {
        console.error('❌ Test Error:', error.message);
    }
}

testProductionLogin();
