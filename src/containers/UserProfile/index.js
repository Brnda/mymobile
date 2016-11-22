import React, {Component} from 'react';
import {View, Text} from 'react-native';
import styles from './styles';

class UserProfile extends Component {
  render() {
    return (
        <View style={styles.container}>
          <Text style={styles.message}>Profile view coming soon.</Text>
        </View>
    );
  }
}

export default UserProfile;