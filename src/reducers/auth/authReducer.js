/**
 * Authetication reducer
 *
 */
const {
  LOGIN_REQUEST,
  LOGIN_SUCCESS,
  LOGIN_FAILURE
} = require('../../lib/constants').default;

/**
 * ## authReducer function
 * @param {Object} state - initialState 
 * @param {Object} action - type and payload
 */
export default function authReducer(state = {}, action) {

  switch (action.type) {
    case LOGIN_REQUEST:
      return state
        
  }
  return state
}
