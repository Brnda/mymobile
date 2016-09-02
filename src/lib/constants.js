const APP_CONST_PROD = {
  BaseUrl: 'owal-api.herokuapp.com',
  Port: '80'
};

// Local server
const APP_CONST_LOCALDEV = {
  BaseUrl: '127.0.0.1',
  Port: '3030'
};

// TODO(someone): figure out how to switch between these!
export default APP_CONST_PROD;
//export default APP_CONST_LOCALDEV; // DO NOT CHECK IN!
