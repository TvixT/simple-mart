const http = require('http');

// Test configuration
const HOST = 'localhost';
const PORT = 5000;

// Test helper function
function makeRequest(method, path, data = null, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: HOST,
      port: PORT,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'API-Test/1.0'
      }
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    if (data) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        try {
          const response = {
            status: res.statusCode,
            data: body ? JSON.parse(body) : null
          };
          resolve(response);
        } catch (error) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

// Test functions
async function testHealthCheck() {
  console.log('\n🔍 Testing Health Check...');
  try {
    const response = await makeRequest('GET', '/health');
    console.log(`✅ Status: ${response.status}`);
    console.log(`📄 Response:`, response.data);
    return response.status === 200;
  } catch (error) {
    console.log(`❌ Error:`, error.message);
    return false;
  }
}

async function testUserRegistration() {
  console.log('\n🔍 Testing User Registration...');
  const userData = {
    username: 'testuser' + Date.now(),
    email: `testuser${Date.now()}@example.com`,
    password: 'password123',
    full_name: 'Test User'
  };
  
  try {
    const response = await makeRequest('POST', '/api/auth/register', userData);
    console.log(`✅ Status: ${response.status}`);
    console.log(`📄 Response:`, response.data);
    return response.status === 201 && response.data.user;
  } catch (error) {
    console.log(`❌ Error:`, error.message);
    return false;
  }
}

async function testUserLogin() {
  console.log('\n🔍 Testing User Login...');
  const loginData = {
    email: 'testuser@example.com',
    password: 'password123'
  };
  
  try {
    const response = await makeRequest('POST', '/api/auth/login', loginData);
    console.log(`✅ Status: ${response.status}`);
    console.log(`📄 Response:`, response.data);
    return response.status === 200 && response.data.token;
  } catch (error) {
    console.log(`❌ Error:`, error.message);
    return false;
  }
}

async function testGetProducts() {
  console.log('\n🔍 Testing Get Products...');
  try {
    const response = await makeRequest('GET', '/api/products');
    console.log(`✅ Status: ${response.status}`);
    console.log(`📄 Response:`, response.data);
    return response.status === 200;
  } catch (error) {
    console.log(`❌ Error:`, error.message);
    return false;
  }
}

async function testDatabaseStatus() {
  console.log('\n🔍 Testing Database Status...');
  try {
    const response = await makeRequest('GET', '/db-status');
    console.log(`✅ Status: ${response.status}`);
    console.log(`📄 Response:`, response.data);
    return response.status === 200;
  } catch (error) {
    console.log(`❌ Error:`, error.message);
    return false;
  }
}

// Main test runner
async function runTests() {
  console.log('🚀 Starting Simple Mart API Tests...');
  console.log(`🔗 Testing server at: http://${HOST}:${PORT}`);
  
  const tests = [
    { name: 'Health Check', func: testHealthCheck },
    { name: 'Database Status', func: testDatabaseStatus },
    { name: 'Get Products', func: testGetProducts },
    { name: 'User Registration', func: testUserRegistration },
    { name: 'User Login', func: testUserLogin }
  ];
  
  let passed = 0;
  let failed = 0;
  
  for (const test of tests) {
    try {
      const result = await test.func();
      if (result) {
        passed++;
      } else {
        failed++;
      }
    } catch (error) {
      console.log(`❌ ${test.name} failed with error:`, error.message);
      failed++;
    }
    
    // Small delay between tests
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  
  console.log('\n📊 Test Summary:');
  console.log(`✅ Passed: ${passed}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`📈 Success Rate: ${((passed / (passed + failed)) * 100).toFixed(1)}%`);
  
  if (failed === 0) {
    console.log('\n🎉 All tests passed! Simple Mart API is working correctly.');
  } else {
    console.log('\n⚠️  Some tests failed. Check the errors above for details.');
  }
}

// Start testing
runTests().catch(error => {
  console.error('\n💥 Test runner failed:', error.message);
  process.exit(1);
});