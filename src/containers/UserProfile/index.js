import React, {Component, PropTypes} from 'react';
import {View, Text} from 'react-native';
import styles from './styles';
import {connect} from 'react-redux';

class UserProfile extends Component {
  render() {
    let {user} = this.props;
    return (
        <View style={styles.container}>
          <Text style={styles.message}>{user}</Text>
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