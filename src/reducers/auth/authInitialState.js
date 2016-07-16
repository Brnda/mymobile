/**
 * ## Import
 */
import {Record, Map} from 'immutable'
const {
  NOT_AUTHENTICATED
} = require('../../lib/constants').default;

/**
 * ## User
 */
const User = Record({
  auth: NOT_AUTHENTICATED,
  username: ''
})

/**
 * ## InitialState
 */
const InitialState = Map({
  user: new User
})
export default InitialState

