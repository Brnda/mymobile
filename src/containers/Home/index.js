import React, {Component, PropTypes} from 'react';
import {View, Text, AsyncStorage} from 'react-native';
import styles from './styles';
import HomeScreenTile from '../../components/HomeScreenTile'
import * as spacesReducer from '../../reducers/spaces/spacesReducer';
import {connect} from 'react-redux';
import {Actions} from 'react-native-router-flux';
import Orientation from 'react-native-orientation';
import APP_CONST, {TENANT_ID, USER_TOKEN} from '../../lib/constants';

const icons = {
  buildingEntrance: require('./../../icons/building.png'),
  garage: require('./../../icons/garage.png'),
  gym: require('./../../icons/gym.png'),
  laundry: require('./../../icons/laundry.png'),
  myfloor: require('./../../icons/myfloor.png'),
  pool: require('./../../icons/pool.png')
};

class Home extends Component {
  constructor() {
    super();
    this._ws = new WebSocket(`ws://${APP_CONST.BaseUrl}:${APP_CONST.PortWS}/`);
  }

  componentWillMount() {
    Orientation.lockToPortrait();
    AsyncStorage.getItem(USER_TOKEN).then((token) => {
      this.props.updateSpaces(token);
    });
    //this._setupWebService();
  }

  _setupWebService() {

    this._ws.onmessage = (e) => {
      AsyncStorage.getItem(TENANT_ID).then((id) => {
        if(id && id === e.data) {
          AsyncStorage.getItem(USER_TOKEN).then((token) => {
            this.props.updateSpaces(token);
          })
        }
      });
    };

    this._ws.onerror = (e) => {
      // an error occurred
      console.error(e.message);
    };

    this._ws.onclose = (e) => {
      // connection closed
      console.error(e.code, e.reason);
    };
  }

  componentWillUnmount() {
    this._ws.close();
  }

  render() {
    return (
        <View style={styles.container}>
          <View style={styles.header}>
            <Text style={styles.headerText}>SPACES</Text>
          </View>
          <View style={styles.row}>
            <HomeScreenTile text="Front Door"
                onSelect={this.props.selectSpace}
                spaceId={this.props.spaces.main_entrance.name}
                icon={icons['buildingEntrance']}/>
            <HomeScreenTile text="My Floor"
                onSelect={this.props.selectSpace}
                spaceId={this.props.spaces.my_floor._id}
                icon={icons['myfloor']}/>
          </View>
          <View style={styles.row}>
            <HomeScreenTile text="Laundry"
                onSelect={this.props.selectSpace}
                spaceId={this.props.spaces.laundry.name}
                icon={icons['laundry']}
                statusBarFilled={this.props.spaces.laundry.status_bar_filled}
                statusBarTotal={this.props.spaces.laundry.status_bar_total}
                fetching={this.props.fetching}/>
            <HomeScreenTile text="Gym"
                onSelect={this.props.selectSpace}
                spaceId={this.props.spaces.gym.name}
                icon={icons['gym']}
                statusBarFilled={this.props.spaces.gym.status_bar_filled}
                statusBarTotal={this.props.spaces.gym.status_bar_total}
                fetching={this.props.fetching}/>
          </View>
          <View style={styles.row}>
            <HomeScreenTile text="Pool"
                onSelect={this.props.selectSpace}
                spaceId={this.props.spaces.pool.name}
                icon={icons['pool']}
                statusBarFilled={this.props.spaces.pool.status_bar_filled}
                statusBarTotal={this.props.spaces.pool.status_bar_total}
                fetching={this.props.fetching}/>
            <HomeScreenTile text="Garage"
                onSelect={this.props.selectSpace}
                spaceId={this.props.spaces.garage.name}
                icon={icons['garage']}
                statusBarFilled={this.props.spaces.garage.status_bar_filled}
                statusBarTotal={this.props.spaces.garage.status_bar_total}
                fetching={this.props.fetching}/>
          </View>
        </View>
    );
  }
}

Home.propTypes = {
  fetching: PropTypes.bool.isRequired
};

const mapStateToProps = (state) => {
  return {
    fetching: state.spaces.get('FETCHING'),
    spaces: state.spaces.get('SPACES')
  }
};

const mapDispatchToProps = (dispatch) => {
  return {
    updateSpaces: (token) => {
      dispatch(spacesReducer.updateSpaces(token))
    },
    selectSpace: (spaceId) => {
      dispatch(spacesReducer.selectSpace(spaceId));
      Actions.viewVideo();
    }
  }
};

export default connect(mapStateToProps, mapDispatchToProps)(Home);
