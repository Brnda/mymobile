import React, {Component} from 'react';
import styles from './styles';

import {connect} from 'react-redux';

import {
    View,
    Text
} from 'react-native';

class TenantReview extends Component {
  render() {
    return (
        <View style={styles.container}>
          <Text style={styles.placeHolderText}>Your code is {this.props.code}</Text>
        </View>
    )
  }
}

const mapStateToProps = (state) => {
  return {
    code: state.induction.get('INVITE_CODE')
  }
};

export default connect(mapStateToProps)(TenantReview);