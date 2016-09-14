import React, {Component, PropTypes} from 'react';
import styles from './styles';

import {connect} from 'react-redux';
import {
    View,
    Text,
    TouchableOpacity,
    Image,
    StatusBar
} from 'react-native';
import {Actions} from 'react-native-router-flux';
import InductionHeader from '../../components/InductionHeader';

class TenantReview extends Component {
  _onPressContinueButton() {
    Actions.lastTenantQuestion();
  }

  render() {
    const {user} = this.props;
    const longAddress = user && user.address2 !== '' ? (
        <View>
          <Text style={styles.tenantDetailText}>{user.address2}</Text>
        </View>)
        : null;

    return (
        <View style={styles.container}>
          <StatusBar hidden={true}/>
          <InductionHeader/>
          <View style={styles.header}>
            <Text style={styles.headerText}>
              Welcome home {user.apartment}. Is this your correct address?
            </Text>
          </View>

          <View style={styles.tenantAddressDetails}>
            <View>
              <View>
                <Text style={styles.tenantDetailText}>{user.address1}</Text>
              </View>
              {longAddress}
              <View>
                <Text style={styles.tenantDetailText}>{user.city_state_zip}</Text>
              </View>
            </View>
          </View>
          <View style={styles.tenantAddressButtoms}>
            <TouchableOpacity style={styles.tenantButton} >
              <Text style={styles.tenantButtonText}>NO</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.tenantButton} onPress={this._onPressContinueButton}>
              <Text style={styles.tenantButtonText}>YES</Text>
            </TouchableOpacity>
          </View>
        </View>
    )
  }
}

TenantReview.propTypes = {
  user: PropTypes.object.isRequired
};

const mapStateToProps = (state) => {
  return {
    user: state.induction.get('USER')
  }
};

export default connect(mapStateToProps)(TenantReview);