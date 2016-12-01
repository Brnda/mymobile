import React, {Component, PropTypes} from 'react';
import {View, Text, AsyncStorage, TouchableHighlight} from 'react-native';
import styles from './styles';
import {connect} from 'react-redux';
import {Actions} from 'react-native-router-flux';

class UserProfile extends Component {
  render() {
    const {user} = this.props;
    //<Text style={styles.message}>User: {JSON.stringify(user, null, 2)}</Text>
    return (
        <View style={styles.container}>

          <View>
            <Text style={styles.tenantDetailText}>{user.address1}</Text>
          </View>
          {longAddress}
          <TouchableHighlight  onPress={() => {AsyncStorage.clear(); Actions.initial();}}>
            <Text>Logout</Text>
          </TouchableHighlight>
        </View>
    );
  }
}

UserProfile.propTypes = {
  user: PropTypes.object.isRequired
};

const mapStateToProps = (state) => {
  return {
    user: state.induction.get('USER')
  }
};

export default connect(mapStateToProps)(UserProfile);