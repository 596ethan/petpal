package com.petpal.server.common.api;

import java.util.List;

public record ApiPageResult<T>(List<T> items, long pageNo, long pageSize, long total) {
}
