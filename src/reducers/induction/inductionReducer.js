import {Map} from 'immutable';
import {Actions} from 'react-native-router-flux';
import APP_CONST, {USER_TOKEN} from '../../lib/constants';
import {AsyncStorage} from 'react-native';

//Actions
export const SEND_INVITATION = 'InductionState/SEND_INVITATION';
export const SEND_INVITATION_FAIL = 'InductionState/SEND_INVITATION_FAIL';
export const TOGGLE_INCLUDE_DIR = 'InductionState/TOGGLE_INCLUDE_DIR';
export const INVITE_ERROR = 'InductionState/INVITE_ERROR';
export const INVITE_ERROR_RESET = 'InductionState/INVITE_ERROR_RESET';

//Action creators
export const resetInviteError = () => {
  return {
    type: INVITE_ERROR_RESET
  };
};

export const addNametoDirectory = (first_name, last_name) => {
  return (dispatch, getState) => {
    AsyncStorage.getItem(USER_TOKEN).then((token) => {
      fetch(`http://${APP_CONST.BaseUrl}:${APP_CONST.Port}/api/v1/directory/update`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({token, show_full_name_in_directory: true, first_name, last_name})
      })
          .then((res) => res.json())
          .then((json) => {
            Actions.enjoy();
          })
          .catch((err) => {
            console.log(`Got an error ${err}`)
          })
    }).done();

  };
};

export const checkInviteCode = (code) => {
  return (dispatch) => {
    fetch(`http://${APP_CONST.BaseUrl}:${APP_CONST.Port}/api/v1/invitecode/verify`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({code})
    })
        .then((res) => res.json())
        .then((json) => {
          if (json.ok) {
            dispatch({
              type: SEND_INVITATION,
              payload: {
                auth: json.auth,
                user: json.user
              }
            });

            AsyncStorage.setItem('BUILDING_ID', json.user.building_id).done();
            AsyncStorage.setItem(USER_TOKEN, json.auth.token).then((err) => {
              Actions.tenatReview();
            });
          } else {
            dispatch({
              type: INVITE_ERROR,
              message: 'Token not valid.'
            });
          }
        })
        .catch((err) => {
          dispatch({
            type: INVITE_ERROR,
            message: 'Network problem.'
          });
        });
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
    case INVITE_ERROR:
      return state.set('ERROR', action.message);
    case INVITE_ERROR_RESET:
      return state.set('ERROR', null);
    case TOGGLE_INCLUDE_DIR:
      return state.set('INCLUDE_DIR', !state.get('INCLUDE_DIR'))
    case SEND_INVITATION:
      return state.set('USER', action.payload.user);
  }
  return state;
}
