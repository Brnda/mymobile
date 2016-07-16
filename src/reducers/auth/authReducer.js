/**
 * Authentication reducer
 *
 */
const {
  LOGIN_REQUEST,
  AUTHENTICATED
} = require('../../lib/constants').default;
import InitialState from './authInitialState'

const initialState = InitialState
/**
 * ## authReducer function
 * @param {Object} state - initialState 
 * @param {Object} action - type and payload
 */
export default function authReducer(state = initialState, action) {

  switch (action.type) {
    case LOGIN_REQUEST:
      console.log(`user .. . .. .. ${state.getIn(['user','username'])}`)
      return state.setIn(['user','username'], action.payload)
  }
  return state
}
