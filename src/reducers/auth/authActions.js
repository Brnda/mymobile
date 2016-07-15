/**
 * Action creator for authentication modules.
 * 
 */
const {
  LOGIN_REQUEST
} = require('../../lib/constants').default;

export function loginRequest(username) {
  return {
    type: LOGIN_REQUEST,
    payload: username
  };
}