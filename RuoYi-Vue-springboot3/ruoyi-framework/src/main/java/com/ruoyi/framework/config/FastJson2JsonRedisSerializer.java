package com.ruoyi.framework.config;

import java.nio.charset.Charset;
import org.springframework.data.redis.serializer.RedisSerializer;
import org.springframework.data.redis.serializer.SerializationException;
import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONReader;
import com.alibaba.fastjson2.JSONWriter;
import com.alibaba.fastjson2.filter.Filter;
import com.ruoyi.common.constant.Constants;
import com.ruoyi.common.core.domain.model.LoginUser;

/**
 * Redis使用FastJson序列化
 * 
 * @author ruoyi
 */
public class FastJson2JsonRedisSerializer<T> implements RedisSerializer<T>
{
    public static final Charset DEFAULT_CHARSET = Charset.forName("UTF-8");

    static final Filter AUTO_TYPE_FILTER = JSONReader.autoTypeFilter(Constants.JSON_WHITELIST_STR);

    private Class<T> clazz;

    public FastJson2JsonRedisSerializer(Class<T> clazz)
    {
        super();
        this.clazz = clazz;
    }

    @Override
    public byte[] serialize(T t) throws SerializationException
    {
        if (t == null)
        {
            return new byte[0];
        }
        String serialized = JSON.toJSONString(t, JSONWriter.Feature.WriteClassName);
        if (t instanceof LoginUser loginUser)
        {
            // Explicit Redis-only field: ordinary JSON serializers must never expose it.
            com.alibaba.fastjson2.JSONObject session = JSON.parseObject(serialized);
            session.put("_credentialFingerprint", loginUser.getCredentialFingerprint());
            serialized = session.toJSONString();
        }
        return serialized.getBytes(DEFAULT_CHARSET);
    }

    @Override
    public T deserialize(byte[] bytes) throws SerializationException
    {
        if (bytes == null || bytes.length <= 0)
        {
            return null;
        }
        String str = new String(bytes, DEFAULT_CHARSET);

        T value = JSON.parseObject(str, clazz, AUTO_TYPE_FILTER);
        if (value instanceof LoginUser loginUser)
        {
            loginUser.setCredentialFingerprint(JSON.parseObject(str).getString("_credentialFingerprint"));
        }
        return value;
    }
}
