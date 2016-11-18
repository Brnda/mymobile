import React, {Component, PropTypes} from 'react';
import {View, Text, AsyncStorage, ActivityIndicator,Dimensions} from 'react-native';
import styles from './styles';
import HomeScreenTile from '../../components/HomeScreenTile'
import * as spacesReducer from '../../reducers/spaces/spacesReducer';
import {connect} from 'react-redux';
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
  }

  componentWillUnmount() {
    this._ws.close();
  }

  render() {
    const {width, height} = Dimensions.get('window');
    return (
        <View style={styles.container}>
          <View style={styles.header}>
            <Text style={styles.headerText}>SPACES</Text>
          </View>
          <View style={styles.row}>
            <HomeScreenTile text="Front Door"
                            onSelect={this.props.selectSpace}
                            spaceId={this.props.spaces.main_entrance._id}
                            icon={icons['buildingEntrance']}
                            enabled={!this.props.fetching}/>
            <HomeScreenTile text="My Floor"
                            onSelect={this.props.selectSpace}
                            spaceId={this.props.spaces.my_floor._id}
                            icon={icons['myfloor']}
                            enabled={!this.props.fetching}/>
          </View>
          <View style={styles.row}>
            <HomeScreenTile text="Laundry"
                            onSelect={this.props.selectSpace}
                            spaceId={this.props.spaces.laundry._id}
                            icon={icons['laundry']}
                            statusBarFilled={this.props.spaces.laundry.status_bar_filled}
                            statusBarTotal={this.props.spaces.laundry.status_bar_total}
                            enabled={!this.props.fetching}/>
            <HomeScreenTile text="Gym"
                            onSelect={this.props.selectSpace}
                            spaceId={this.props.spaces.gym._id}
                            icon={icons['gym']}
                            statusBarFilled={this.props.spaces.gym.status_bar_filled}
                            statusBarTotal={this.props.spaces.gym.status_bar_total}
                            enabled={!this.props.fetching}/>
          </View>
          <View style={styles.row}>
            <HomeScreenTile text="Pool"
                            onSelect={this.props.selectSpace}
                            spaceId={this.props.spaces.pool._id}
                            icon={icons['pool']}
                            statusBarFilled={this.props.spaces.pool.status_bar_filled}
                            statusBarTotal={this.props.spaces.pool.status_bar_total}
                            enabled={!this.props.fetching}/>
            <HomeScreenTile text="Garage"
                            onSelect={this.props.selectSpace}
                            spaceId={this.props.spaces.garage._id}
                            icon={icons['garage']}
                            statusBarFilled={this.props.spaces.garage.status_bar_filled}
                            statusBarTotal={this.props.spaces.garage.status_bar_total}
                            enabled={!this.props.fetching}/>
          </View>
          {this.props.fetching &&
          <View style={[styles.overlay, { height, width}]}>
            <ActivityIndicator
                animating={true}
                style={styles.activityIndicator}
                color="black"
                size="large"/>
          </View>
          }
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
    }
  }
};

export default connect(mapStateToProps, mapDispatchToProps)(Home);
