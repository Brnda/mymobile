import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import logger from 'redux-logger';

/**
* ## Reducer
* The reducer contains all reducers
*/
import reducer from '../reducers';

/**
 * ## creatStoreWithMiddleware
 * Like the name...
 */ 
const createStoreWithMiddleware = applyMiddleware(
  thunk,
  logger
)(createStore);

/**
 * ## configureStore
 * @param {Object} the state
 *
 */ 
export default function configureStore(initialState) {
  return createStoreWithMiddleware(reducer, initialState);
};
