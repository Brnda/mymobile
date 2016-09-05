import {Map} from 'immutable';
import {Actions} from 'react-native-router-flux';
import APP_CONST from '../../lib/constants'

//Actions
export const SEND_INVITATION = 'InductionState/SEND_INVITATION';
export const SEND_INVITATION_FAIL = 'InductionState/SEND_INVITATION_FAIL';
export const TOGGLE_INCLUDE_DIR = 'InductionState/TOGGLE_INCLUDE_DIR';

//Action creators
export const setInviteCode = (code) => {
  Actions.tenatReview();
  return {
    type: SET_INVITATION,
    payload: code
  };
};

export const checkInviteCode = (code) => {
  return (dispatch) => {
    fetch(`http://${APP_CONST.BaseUrl}:${APP_CONST.Port}/api/verifyinvitecode`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({code})
    })
    .then((res) => res.json())
    .then((json) => {
      if(json.ok) {
        dispatch({
          type: SEND_INVITATION,
          payload: {
            auth: json.auth,
            user: json.user
          }
        });
        Actions.tenatReview();
      } else {
        //dispatches invalid invitation token.
        console.log("Response does not have 'token' and 'auth'");
      }
    })
    .catch((err) => { console.log('Got an error: ${err}')});
  };
};

export const includeInDirectory = () => {
  return {
    type: TOGGLE_INCLUDE_DIR
    };
};

//Reducer
const initialState = Map({'INCLUDE_DIR': true});
/**
 * ## inductionReducer function
 * @param {Object} state - initialState
 * @param {Object} action - type and payload
 */
export default function inductionReducer(state = initialState, action) {
  switch (action.type) {
    case TOGGLE_INCLUDE_DIR:
      return state.set('INCLUDE_DIR', !state.get('INCLUDE_DIR'))
    case SEND_INVITATION:
      return state.set('USER', action.payload.user)
          .set('SESSION_TOKEN', action.payload.auth.token)
          .set('SESSION_TOKEN_CAN_DELEGATE', action.payload.auth.can_delegate);
    case SEND_INVITATION_FAIL:
      return state.delete('USER').delete('SESSION_TOKEN')
          .delete('SESSION_TOKEN_CAN_DELEGATE');
  }
  return state;
}
