const APP_CONST_PROD = {
  BaseUrl: 'owal-api.herokuapp.com',
  Port: '80',
  PortWS: 3000
};

// Local server
const APP_CONST_LOCALDEV = {
  BaseUrl: '192.168.0.78',
  // BaseUrl: '127.0.0.1',
  Port: '3030',
  PortWS: 3000
};

export const SKIP_INDUCTION_KEY = '@AsyncStorage:skipInduction';
export const USER_TOKEN = '@AsyncStorage:userToken';
export const TENANT_ID = '@AsyncStorage:tenantID';
export const TENANT = '@AsyncStorage:tenant';

// DO NOT SUBMIT IF UNCOMMENTED
//export default APP_CONST_LOCALDEV;

export default APP_CONST_PROD;