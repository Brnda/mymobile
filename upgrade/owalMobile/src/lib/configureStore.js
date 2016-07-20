import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';

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
  thunk
)(createStore);

/**
 * ## configureStore
 * @param {Object} the state
 *
 */ 
export default function configureStore(initialState) {
  return createStoreWithMiddleware(reducer, initialState);
};
