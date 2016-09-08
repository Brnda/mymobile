import React, {Component} from 'react';
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
    return (
        <View style={styles.container}>
          <StatusBar hidden={true}/>
          <InductionHeader/>
          <View style={styles.header}>
            <Text style={styles.headerText}>Welcome home</Text>
          </View>
          <View style={styles.header}>
            <Text style={styles.headerText}>{this.props.user.first_name}!</Text>
          </View>
          <View style={styles.subHeader}>
            <Text style={styles.subHeaderText}>Please confirm your information.</Text>
          </View>
          <View style={styles.tenantDetails}>
            <View style={styles.tenantDetailsRow}>
              <View style={styles.tenantDetailColumnLeft}>
                <Text style={styles.tenantDetailBoldText}>First name</Text>
              </View>
              <View style={styles.tenantDetailColumnRight}>
                <Text style={styles.tenantDetailText}>{this.props.user.first_name}</Text>
              </View>
            </View>
            <View style={styles.tenantDetailsRow}>
              <View style={styles.tenantDetailColumnLeft}>
                <Text style={styles.tenantDetailBoldText}>Last name</Text>
              </View>
              <View style={styles.tenantDetailColumnRight}>
                <Text style={styles.tenantDetailText}>{this.props.user.last_name}</Text>
              </View>
            </View>
            <View style={styles.tenantDetailsRow}>
              <View style={styles.tenantDetailColumnLeft}>
                <Text style={styles.tenantDetailBoldText}>Address</Text>
              </View>
              <View style={styles.tenantDetailColumnRight}>
                <Text style={styles.tenantDetailText}>{this.props.user.address1}</Text>
              </View>
            </View>
            <View style={styles.tenantDetailsRow}>
              <View style={styles.tenantDetailColumnLeft}>
                <Text style={styles.tenantDetailText}></Text>
              </View>
              <View style={styles.tenantDetailColumnRight}>
                <Text style={styles.tenantDetailText}>{this.props.user.address2}</Text>
              </View>
            </View>
            <View style={styles.tenantDetailsRow}>
              <View style={styles.tenantDetailColumnLeft}>
                <Text style={styles.tenantDetailText}></Text>
              </View>
              <View style={styles.tenantDetailColumnRight}>
                <Text style={styles.tenantDetailText}>{this.props.user.city_state_zip}</Text>
              </View>
            </View>
          </View>
          <View style={styles.tenatDataValid}>
            <Text style={styles.somethingWrongTextSmall}>Something is wrong.</Text>
          </View>
          <TouchableOpacity style={styles.continueButton} onPress={this._onPressContinueButton}>
            <Text style={styles.continueButtonText}>CONTINUE</Text>
          </TouchableOpacity>
        </View>
    )
  }
}

const mapStateToProps = (state) => {
  return {
    user: state.induction.get('USER')
  }
};

export default connect(mapStateToProps)(TenantReview);