import { Map } from 'immutable';
import { Actions } from 'react-native-router-flux';

//Actions
export const SET_INVITATION = 'InductionState/SET_INVITATION';
const INVITE_CODE = 'INVITE_CODE';


//Action creators
export const setInviteCode = (code) => {
  Actions.pop();
  console.log("Invite code is: " + code);
  return {
    type: SET_INVITATION,
    payload: code
  };
};

//Reducer
const initialState = Map({});
/**
 * ## inductionReducer function
 * @param {Object} state - initialState
 * @param {Object} action - type and payload
 */
export default function inductionReducer(state = initialState, action) {
  switch (action.type) {
    case SET_INVITATION:
      return state.set(INVITE_CODE, action.payload);
  }
  return state;
}
