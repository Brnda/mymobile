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
        <View style={styles.header}><Text>SPACES { this.props.fetching ? " READY" : " LOADING"} </Text></View>
        <View style={styles.row}>
          <HomeScreenTile text="MAIN ENTRANCE" containerStyle={{backgroundColor: '#ff0'}}/>
          <HomeScreenTile text="MY FLOOR" containerStyle={{backgroundColor: '#0f0'}}/>
        </View>
        <View style={styles.row}>
          <HomeScreenTile text="LAUNDRY" containerStyle={{backgroundColor: '#ff0'}}/>
          <HomeScreenTile text="GYM" containerStyle={{backgroundColor: '#0f0'}}/>
        </View>
        <View style={styles.row}>
          <HomeScreenTile
            text="POOL"
            containerStyle={{backgroundColor: '#ff0'}}
            statusText="Status Unavailable"
            statusTextStyle={{color: '#ccc'}}/>
          <HomeScreenTile text="GARAGE" containerStyle={{backgroundColor: '#0f0'}}/>
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
    fetching: state.spaces.get('FETCHING')
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