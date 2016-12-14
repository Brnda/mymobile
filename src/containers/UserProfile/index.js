import React, {Component, PropTypes} from 'react';
import {View, Text,
  AsyncStorage, TouchableHighlight} from 'react-native';
import styles from './styles';
import {Actions} from 'react-native-router-flux';
import {TENANT} from '../../lib/constants';
import {connect} from 'react-redux';

class UserProfile extends Component {

  componentWillMount() {
    console.log("Loading tenant...");
    AsyncStorage.getItem(TENANT).then((tenant) => {
      console.log("Loaded tenant string: " + tenant);
      let user = JSON.parse(tenant);
      this.setState({user});
      console.log("Loaded tenant object: " + JSON.stringify(user, null, 2));
    });
  }

  logout() {
    AsyncStorage.clear();
    Actions.app();
  }

  render() {
    let user = (this.state && this.state.user) || {};
    let text = //JSON.stringify(user, null, 2);
      JSON.stringify(
        {apt: user.apt, addr1: user.address1, addr2: user.address2},
        null, 2
      );
    return (
        <View style={styles.container}>
          <Text style={styles.message}>{text}</Text>
          <TouchableHighlight onPress={() => this.logout() }>
            <Text style={styles.message}>Logout</Text>
          </TouchableHighlight>
        </View>
    );
  }
}


UserProfile.propTypes = {
  user: PropTypes.object
};

export default UserProfile;