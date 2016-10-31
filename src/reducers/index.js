import induction from './induction/inductionReducer'
import spaces from './spaces/spacesReducer'
import camera from './camera/cameraReducer'

import {combineReducers} from 'redux'

/**
 * ## CombineReducers
 *
 * the rootReducer will call each and every reducer with the state and action
 * EVERY TIME there is a basic action
 */
const rootReducer = combineReducers({
  induction,
  spaces,
  camera
})

export default rootReducer
