import {Map} from 'immutable';
import {Actions} from 'react-native-router-flux';
import APP_CONST from '../../lib/constants'

// Actions
export const GET_CAMERA_REQUEST = 'CameraReducer/GET_CAMERA_REQUEST';
export const GET_CAMERA_RESPONSE = 'CameraReducer/GET_CAMERA_RESPONSE';

// Action creators

export const getCameraRequest = () => {
  return {
    type: GET_CAMERA_REQUEST
  };
};

export const getCameraResponse = (response) => {
  return {
    type: GET_CAMERA_RESPONSE,
    response
  }
};

// Reducer
const initialState = Map({
  'CAMERA_INFO': null,
  'GETTING': true
});

export const getCamera = (camera_id) => {
  return (dispatch, getState) => {
    const state = getState();
    const token = state.induction.get('SESSION_TOKEN');

    dispatch(getCameraRequest());
    fetch(`http://${APP_CONST.BaseUrl}:${APP_CONST.Port}/api/v1/camera/get`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({token, camera_id})
    })
      .then((res) => res.json())
      .then((json) => {
        dispatch(getCameraResponse(json));
      })
      .catch((err) => {console.error(`Got an error ${err}`)})
  };
};

export default function spaces(state = initialState, action) {
  switch (action.type) {
    case GET_CAMERA_REQUEST:
      return state.set('GETTING', true);
    case GET_CAMERA_RESPONSE:
      return state.set('CAMERA', action.response).set('GETTING', false);
    default:
      return state;
  }
}
