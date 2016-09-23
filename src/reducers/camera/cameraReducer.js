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
    //const token = state.induction.get('SESSION_TOKEN');
    // DO NOT SUBMIT!
    const token = "ntwpFLrUBcyMRpDEr1AefhXAwZIhydnn";
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
        console.log("Camera gotten!");
        dispatch(getCameraResponse(json));
      })
      .catch((err) => {console.log(`Got an error ${err}`)})
  };
};

export default function spaces(state = initialState, action) {
  //console.log("spaces reducer, state=" + JSON.stringify(state, null, 2) + " action=" + JSON.stringify(action, null, 2));
  switch (action.type) {
    case GET_CAMERA_REQUEST:
      console.log("Getting is now True");
      return state.set('GETTING', true);
    case GET_CAMERA_RESPONSE:
      console.log("Getting is now False");
      console.log("Got camera info: " + action.response);
      return state.set('CAMERA', action.response).set('GETTING', false);
    default:
      console.log("!! UNKNOWN ACTION TYPE " + action.type);
  }
  return state;
}
