import React, {Component, PropTypes} from 'react';
import {View, Text} from 'react-native';
import styles from './styles';
import HomeScreenTile from '../../components/HomeScreenTile'
import * as spacesReducer from '../../reducers/spaces/spacesReducer';
import {connect} from 'react-redux';
import {Actions} from 'react-native-router-flux';

class Home extends Component {

  componentWillMount() {
    this.props.updateSpaces();
  }

  render() {
    return (
      <View style={styles.container}>
        <View style={styles.header}><Text style={styles.headerText}>SPACES { this.props.fetching ? " LOADING" : ""} </Text></View>
        <View style={styles.row}>
          <HomeScreenTile
            text={this.props.spaces.main_entrance.name}
            containerStyle={{}}
            onSelect={this.props.selectSpace}
            spaceId={this.props.spaces.main_entrance._id}
            iconName={this.props.spaces.main_entrance.icon_name}
          />
          <HomeScreenTile
            text={this.props.spaces.my_floor.name}
            onSelect={this.props.selectSpace}
            spaceId={this.props.spaces.my_floor._id}
            iconName={this.props.spaces.my_floor.icon_name}
          />
        </View>
        <View style={styles.row}>
          <HomeScreenTile
            text={this.props.spaces.laundry.name}
            onSelect={this.props.selectSpace}
            spaceId={this.props.spaces.laundry._id}
            iconName={this.props.spaces.laundry.icon_name}
            statusText={this.props.spaces.laundry.status_text}
            statusColor={this.props.spaces.laundry.status_color}
            statusBarFilled={this.props.spaces.laundry.status_bar_filled}
            statusBarTotal={this.props.spaces.laundry.status_bar_total}
            fetching={this.props.fetching}
          />
          <HomeScreenTile
            text={this.props.spaces.gym.name}
            onSelect={this.props.selectSpace}
            spaceId={this.props.spaces.gym._id}
            iconName={this.props.spaces.gym.icon_name}
            statusText={this.props.spaces.gym.status_text}
          status/>
        </View>
        <View style={styles.row}>
          <HomeScreenTile
            text={this.props.spaces.pool.name}
            onSelect={this.props.selectSpace}
            spaceId={this.props.spaces.pool._id}
            iconName={this.props.spaces.pool.icon_name}/>
          <HomeScreenTile
            text={this.props.spaces.garage.name}
            onSelect={this.props.selectSpace}
            spaceId={this.props.spaces.garage._id}
            iconName={this.props.spaces.garage.icon_name}/>
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
    updateSpaces: () => {
      dispatch(spacesReducer.updateSpaces())
    },
    selectSpace: (spaceId) => {
      dispatch(spacesReducer.selectSpace(spaceId));
      Actions.viewVideo();
    }
  }
};

export default connect(mapStateToProps, mapDispatchToProps)(Home);
