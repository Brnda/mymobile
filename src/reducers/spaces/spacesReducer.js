import {Map} from 'immutable';
import APP_CONST, {USER_TOKEN} from '../../lib/constants'
import {AsyncStorage} from 'react-native';
import {Actions} from 'react-native-router-flux';

// Actions
export const FETCH_SPACES_REQUEST = 'HomeScreenState/FETCH_SPACES_REQUEST';
export const FETCH_SPACES_RESPONSE = 'HomeScreenState/FETCH_SPACES_RESPONSE';

export const GET_CAMERA_RESPONSE = 'CameraReducer/GET_CAMERA_RESPONSE';

// Due to a bug in react-native-router-flux, props cannot be passed in a Route Action.
// So, we must set the chosen scene in the global state.
// See https://github.com/aksonov/react-native-router-flux/issues/167
export const SPACE_SELECTED = 'HomeScreenState/SPACE_SELECTED';

const defaultSpacesSet = {
  main_entrance: {
    name: "Main Entrance",
    enabled: false,
    icon_name: "buildingentrance",
    has_status: false
  },
  my_floor: {
    name: "My Floor",
    enabled: false,
    icon_name: "myfloor",
    has_status: false,
  },
  laundry: {
    name: "Laundry",
    enabled: false,
    icon_name: "laundry",
    has_status: true,
    status_bar_filled: 2,
    status_bar_total: 4,
    status_color: "gray",
    status_text: "No Data"
  },
  gym: {
    name: "Gym",
    enabled: false,
    icon_name: "gym",
    has_status: true,
    status_bar_filled: 2,
    status_bar_total: 4,
    status_color: "gray",
    status_text: "No Data"
  },
  pool: {
    name: "Pool",
    enabled: false,
    icon_name: "pool",
    has_status: true,
    status_bar_filled: 2,
    status_bar_total: 4,
    status_color: "gray",
    status_text: "No Data"
  },
  garage: {
    name: "Garage",
    enabled: false,
    icon_name: "garage",
    has_status: true,
    status_bar_filled: 2,
    status_bar_total: 4,
    status_color: "gray",
    status_text: "No Data"
  }
};

// Action creators
export const fetchSpacesRequest = () => {
  return {
    type: FETCH_SPACES_REQUEST
  };
};

export const fetchSpacesResponse = (json) => {
  return {
    type: FETCH_SPACES_RESPONSE,
    payload: json
  }
};

export const getCameraResponse = (response) => {
  return {
    type: GET_CAMERA_RESPONSE,
    response
  }
};

export const selectSpace = (spaceId) => {
  if (!spaceId) return { type: "NO_OP"};

  return (dispatch, getState) => {
    //Set the space that was selected and set the fetching flag once again.
    dispatch({
      type: SPACE_SELECTED,
      payload: {spaceId}
    });

    //Load URI of the camera that was selected.
    const state = getState();
    const spaces = state.spaces.get('SPACES');
    let camera_id = null;

    for(key of Object.keys(spaces)) {
      if(spaceId === spaces[key]._id) {
        camera_id = spaces[key].camera_ids[0];
      }
    }

    if(camera_id) {
      AsyncStorage.getItem(USER_TOKEN).then((token) => {
        fetch(`http://${APP_CONST.BaseUrl}:${APP_CONST.Port}/api/v1/camera/get`, {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({token, camera_id})
        }).then((res) => res.json())
          .then((json) => {
              if (!json.cameras || !json.cameras[0] || !json.cameras[0].streams
                    || !json.cameras[0].streams[0]) {
                console.error(`Camera not found`);
              } else {
                dispatch(getCameraResponse(json));
                Actions.viewVideo({uri: json.cameras[0].streams[0], title:json.cameras[0].description});
              }
          })
          .catch((err) => {console.error(`Got an error ${err}`)});
      });
    }
  };
};

// Reducer
const initialState = Map({
  'FETCHING': true,
  'SPACES': defaultSpacesSet,
  'SPACE_ID': null,
  'CAMERA': null
});

export const updateSpaces = (token) => {
  return (dispatch) => {
    dispatch(fetchSpacesRequest());
    fetch(`http://${APP_CONST.BaseUrl}:${APP_CONST.Port}/api/v1/space/list`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({token})
    }).then((res) => res.json())
      .then((json) => {
        dispatch(fetchSpacesResponse(json));
      })
      .catch((err) => {console.error(`Got an error ${err}`)});
  };
};

export default function spaces(state = initialState, action) {
  switch (action.type) {
    case FETCH_SPACES_REQUEST:
      return state.set('FETCHING', true);
    case FETCH_SPACES_RESPONSE:
      return state.set('SPACES', action.payload.spaces).set('FETCHING', false);
    case SPACE_SELECTED:
      return state.set('SPACE_ID', action.payload.spaceId).set('FETCHING', true);
    case GET_CAMERA_RESPONSE:
      return state.set('CAMERA', action.response).set('FETCHING', false);
    default:
      return state;
  }
}