import React, {Component, PropTypes} from 'react';
import {View, Text,
  AsyncStorage, TouchableHighlight} from 'react-native';
import styles from './styles';
import {Actions} from 'react-native-router-flux';
import {TENANT} from '../../lib/constants';

class UserProfile extends Component {

  constructor() {
    super();
    this.user = {};
  }

  componentWillMount() {
    console.log("Loading tenant...");
    AsyncStorage.getItem(TENANT, (tenant) => {
      console.log("Loaded tenant string: " + tenant);
      this.user = JSON.parse(tenant);
      console.log("Loaded tenant object: " + JSON.stringify(this.user, null, 2));
    })
  }

  logout() {
    AsyncStorage.clear();
    Actions.app();
  }

  render() {
    let user = this.user || {};
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

export default UserProfile;