import {Map} from 'immutable';
import {Actions} from 'react-native-router-flux';
import APP_CONST from '../../lib/constants'

// Actions
export const FETCH_SPACES_REQUEST = 'HomeScreenState/FETCH_SPACES_REQUEST';
export const FETCH_SPACES_RESPONSE = 'HomeScreenState/FETCH_SPACES_RESPONSE';

const defaultSpacesSet = {
  main_entrance: {
    name: "Main Entrance",
    enabled: false,
    icon_name: "main_entrance",
    has_status: false
  },
  my_floor: {
    name: "My Floor",
    enabled: false,
    icon_name: "my_floor",
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
    name: "Garage - please wait",
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
    ...json
  }
};


// Reducer
const initialState = Map({
  'FETCHING': false,
  'SPACES': defaultSpacesSet
});

export const updateSpaces = () => {
  return (dispatch, getState) => {
    const state = getState();
    //const token = state.induction.get('SESSION_TOKEN');
    // DO NOT SUBMIT!
    const token = "ntwpFLrUBcyMRpDEr1AefhXAwZIhydnn";
    dispatch(fetchSpacesRequest());
    fetch(`http://${APP_CONST.BaseUrl}:${APP_CONST.Port}/api/v1/space/list`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({token})
    })
      .then((res) => res.json())
      .then((json) => {
        console.log("Spaces updated!");
        dispatch(fetchSpacesResponse(json));
      })
      .catch((err) => {console.log(`Got an error ${err}`)})
  };
};

export default function spaces(state = initialState, action) {
  console.log("spaces reducer, state=" + JSON.stringify(state, null, 2) + " action=" + JSON.stringify(action, null, 2));
  switch (action.type) {
    case FETCH_SPACES_REQUEST:
      console.log("Fetching is now True");
      return state.set('FETCHING', true);
    case FETCH_SPACES_RESPONSE:
      console.log("Fetching is now False");
      return state.set('SPACES', action.spaces).set('FETCHING', false);
    default:
      console.log("!! UNKNOWN ACTION TYPE " + action.type);
  }
  return state;
}
