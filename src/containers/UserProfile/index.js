import React, {Component, PropTypes} from 'react';
import {View, Text,
  AsyncStorage, TouchableHighlight,
  Image,
  Switch, AlertIOS} from 'react-native';
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

  logoutAlert() {
    AlertIOS.alert(
      'Logout?',
      'You will need a new invite code to log in again.',
      [
        {text: 'Cancel', style: 'cancel'},
        {text: 'Logout', style: 'destructive', onPress: () => this.logout()}
      ]
    )
  }
  render() {
    let user = (this.state && this.state.user) || {};
    let text = //JSON.stringify(user, null, 2);
      JSON.stringify(
        {apt: user.apt, addr1: user.address1, addr2: user.address2},
        null, 2
      );
    let title = (user.first_name || 'FirstName') + ' ' + (user.last_name || 'LastName');
    return (
        <View style={styles.container}>
          <View style={styles.header}>
            <Text style={styles.headerText}>{title}</Text>
          </View>
          <View style={styles.divider} />
          <View>
            <Image source={require("../../components/ChatScreen/img/soon__.jpg")} style={styles.profileImage}/>
          </View>
          <View style={styles.rowWithText}>
            <Text style={styles.rowHeader}>Apt</Text>
            <Text style={styles.rowValue}>{user.apt}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.rowWithSwitch}>
            <Text style={styles.switchQuestion}>Would you like to use your name in the building directory?</Text>
            <Switch value={user.show_full_name_in_directory}/>
          </View>
          <View style={styles.divider} />
          <TouchableHighlight onPress={() => this.logoutAlert() }>
            <Text style={styles.logout}>Logout</Text>
          </TouchableHighlight>
        </View>
    );
  }
}


UserProfile.propTypes = {
  user: PropTypes.object
};

export default UserProfile;