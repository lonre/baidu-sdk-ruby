## 0.0.4 (2014-06-22)
* **OAuth** token_info 验证的 access token 过期或无效返回 nil

## 0.0.3 (2013-12-30)
* 添加部分 REST API, `Baidu::OAuth::RESTClient`
  * get_logged_in_user
  * get_info
  * app_user?
  * has_app_permission?
  * has_app_permissions
  * get_friends
  * are_friends
  * expire_session
  * revoke_authorization
  * query_ip

## 0.0.2 (2013-12-06)
* **OAuth** 添加 Implicit Grant 授权流程
* **OAuth** 添加 Client Credentials 授权流程
* **OAuth** API 修改：Client#code_flow => Client#authorization_code_flow

## 0.0.1 (2013-11-28)
* 首个版本
