const APP_CONST_PROD = {
  BaseUrl: 'owal-api.herokuapp.com',
  Port: '80'
};

// Local server
const APP_CONST_LOCALDEV = {
  BaseUrl: '127.0.0.1',
  Port: '3030'
};

export const SKIP_INDUCTION_KEY = '@AsyncStorage:skipInduction';

// DO NOT SUBMIT IF UNCOMMENTED
//export default APP_CONST_LOCALDEV;

export default APP_CONST_PROD;