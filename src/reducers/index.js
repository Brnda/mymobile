import induction from './induction/inductionReducer'
import spaces from './spaces/spacesReducer'

import {combineReducers} from 'redux'

/**
 * ## CombineReducers
 *
 * the rootReducer will call each and every reducer with the state and action
 * EVERY TIME there is a basic action
 */
const rootReducer = combineReducers({
  induction,
  spaces
})

export default rootReducer
