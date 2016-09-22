import React, {Component, PropTypes} from 'react';
import {View, Text} from 'react-native';
import styles from './styles';
import HomeScreenTile from '../../components/HomeScreenTile'
import * as spacesReducer from '../../reducers/spaces/spacesReducer';
import {connect} from 'react-redux';

class Home extends Component {

  componentWillMount() {
    this.props.updateSpaces();
    console.log("Dispatched updateSpaces");
  }

  render() {
    return (
      <View style={styles.container}>
        <View style={styles.header}><Text>SPACES { this.props.fetching ? " LOADING" : " READY"} </Text></View>
        <View style={styles.row}>
          <HomeScreenTile
            text={this.props.spaces.main_entrance.name}
            containerStyle={{backgroundColor: '#ff0'}}/>
          <HomeScreenTile text={this.props.spaces.my_floor.name} containerStyle={{backgroundColor: '#0f0'}}/>
        </View>
        <View style={styles.row}>
          <HomeScreenTile text={this.props.spaces.laundry.name} containerStyle={{backgroundColor: '#ff0'}}/>
          <HomeScreenTile text={this.props.spaces.gym.name} containerStyle={{backgroundColor: '#0f0'}}/>
        </View>
        <View style={styles.row}>
          <HomeScreenTile
            text={this.props.spaces.pool.name}
            containerStyle={{backgroundColor: '#ff0'}}
            statusText="Status Unavailable"
            statusTextStyle={{color: '#ccc'}}/>
          <HomeScreenTile text={this.props.spaces.garage.name} containerStyle={{backgroundColor: '#0f0'}}/>
        </View>
      </View>
    );
  }
}


Home.propTypes = {
  fetching: PropTypes.bool
};

const mapStateToProps = (state) => {
  return {
    fetching: state.spaces.get('FETCHING'),
    spaces: state.spaces.get('SPACES')
  }
};

const mapDispatchToProps = (dispatch) => {
  return {
    updateSpaces: () => {
      dispatch(spacesReducer.updateSpaces())
    }
  }
};

export default connect(mapStateToProps, mapDispatchToProps)(Home);