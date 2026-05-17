# frozen_string_literal: true

# ======================================================
# Contains code from GitLab FOSS (MIT Licensed)
# Copyright (c) GitLab Inc.
# See .licenses/Gisia/others/gitlab-foss.dep.yml for full license
#
# Modifications and additions copyright (c) 2025-present Liuming Tan
# Licensed under AGPLv3 - see LICENSE file in this repository
# ======================================================

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    'ssh_key' => 'SSHKey',
    'ssh_public_key' => 'SSHPublicKey',
    'json_web_token' => 'JSONWebToken',
    'gitlab_cli_activity_unique_counter' => 'GitLabCliActivityUniqueCounter',
    'rsa_token' => 'RSAToken',
    'hll' => 'HLL',
    'hll_redis_counter' => 'HLLRedisCounter',
    'redis_hll_metric' => 'RedisHLLMetric',
    'hmac_token' => 'HMACToken',
    'html' => 'HTML',
    'html_parser' => 'HTMLParser',
    'html_gitlab' => 'HTMLGitlab',
    'open_api_strategy' => 'OpenApiStrategy',
    'cdn' => 'CDN',
    'chunked_io' => 'ChunkedIO',
    'http_io' => 'HttpIO',
    'google_cdn' => 'GoogleCDN',
    'pdf' => 'PDF',
    'csv' => 'CSV',
    'svg' => 'SVG',
    'binary_stl' => 'BinarySTL',
    'text_stl' => 'TextSTL',
    'open_api' => 'OpenApi',
    'cte' => 'CTE',
    'recursive_cte' => 'RecursiveCTE',
    'sql' => 'SQL',
    'global_search_api' => 'GlobalSearchApi'
  )
end
