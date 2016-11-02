import {Map} from 'immutable';
import APP_CONST from '../../lib/constants'
import firebase from 'firebase';

// Actions
export const FETCH_SPACES_REQUEST = 'HomeScreenState/FETCH_SPACES_REQUEST';
export const FETCH_SPACES_RESPONSE = 'HomeScreenState/FETCH_SPACES_RESPONSE';

// Due to a bug in react-native-router-flux, props cannot be passed in a Route Action.
// So, we must set the chosen scene in the global state.
// See https://github.com/aksonov/react-native-router-flux/issues/167
export const SPACE_SELECTED = 'HomeScreenState/SPACE_SELECTED';
export const UPDATE_SPACES_BARS = 'HomeScreenState/UPDATE_SPACES_BARS';

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

export const selectSpace = (spaceId) => {
  if (!spaceId) return { type: "NO_OP"};

  return {
    type: SPACE_SELECTED,
    payload: {spaceId}
  }
};

// Reducer
const initialState = Map({
  'FETCHING': false,
  'SPACES': defaultSpacesSet,
  'SPACE_ID': null
});

export const updateSpacesBars = (bars) => {
  return {
    type: UPDATE_SPACES_BARS,
    payload: bars
  };
};

export const updateSpaces = (building) => {
  return (dispatch) => {
    firebase.database().ref(`/buildings/${building}`).once('value').then((snapshot) => {
      dispatch(fetchSpacesResponse(snapshot.val()));
    });
  };
};

export default function spaces(state = initialState, action) {
  switch (action.type) {
    case FETCH_SPACES_REQUEST:
      return state.set('FETCHING', true);
    case FETCH_SPACES_RESPONSE:
      return state.set('SPACES', action.payload).set('FETCHING', false);
    case SPACE_SELECTED:
      return state.set('SPACE_ID', action.payload.spaceId);
    case UPDATE_SPACES_BARS:
      return state.set('SPACES', action.payload);
    default:
      return state;
  }
}
