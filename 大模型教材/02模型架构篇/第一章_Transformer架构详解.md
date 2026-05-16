# 第一章：Transformer架构详解

> Transformer是现代大模型的基础架构，本章深入讲解Transformer的各个方面。

## 1.1 Transformer基础架构

### 1.1.1 为什么需要Transformer

在Transformer之前，NLP模型主要依赖循环神经网络(RNN)。

**RNN的问题**：
- 难以并行计算
- 无法同时处理所有输入
- 长距离依赖难以捕捉
- 训练速度慢

**Transformer的优势**：
- 完全基于注意力机制
- 并行计算能力强
- 可以捕获长距离依赖
- 训练速度快

**Transformer的提出**：
2017年，Google在论文《Attention Is All You Need》中提出了Transformer架构。

### 1.1.2 Transformer整体结构

Transformer由编码器(Encoder)和解码器(Decoder)组成。

```
输入层
    ↓
编码器
  ├─ 自注意力层
  ├─ 前馈网络
  └─ 残差连接 + 层归一化
    ↓
解码器
  ├─ 掩码自注意力层
  ├─ 编码器-解码器注意力层
  ├─ 前馈网络
  └─ 残差连接 + 层归一化
    ↓
输出层
``` 

### 1.1.3 自注意力机制

自注意力是Transformer的核心组件。

**基本原理**：
```
输入序列: x = [x₁, x₂, ..., xₙ]

查询 Q = XW_Q
键 K = XW_K
值 V = XW_V

Attention(Q, K, V) = softmax(QKᵀ / √d_k) · V

其中：
X: 输入矩阵 (n × d_model)
W_Q, W_K, W_V: 可学习参数矩阵
d_k: 键的维度
``` 

**数学解释**：

1. **查询(Query)**：当前词与其他词的相关性查询
2. **键(Key)**：每个词的标识，用于匹配查询
3. **值(Value)**：每个词的实际内容

**注意力权重**：
```
Attention(Q, K, V) = softmax(QKᵀ / √d_k)

得分矩阵: S = QKᵀ (n × n)
每个位置的得分表示该位置对其他位置的关注程度
``` 

**加权和**：
```
Output = Attention(Q, K, V) · V

每个位置聚合相关的值向量
``` 

**代码实现**：
```python
import torch
import torch.nn as nn
import torch.nn.functional as F

class SelfAttention(nn.Module):
    def __init__(self, d_model, num_heads):
        super().__init__()
        self.d_model = d_model
        self.num_heads = num_heads
        self.d_k = d_model // num_heads

        # 线性变换
        self.W_Q = nn.Linear(d_model, d_model)
        self.W_K = nn.Linear(d_model, d_model)
        self.W_V = nn.Linear(d_model, d_model)

    def scaled_dot_product_attention(self, Q, K, V, mask=None):
        # 计算注意力分数
        scores = torch.matmul(Q, K.transpose(-2, -1)) / torch.sqrt(self.d_k)

        # 应用mask（如果有）
        if mask is not None:
            scores = scores.masked_fill(mask == 0, -1e9)

        # 计算注意力权重
        attention_weights = F.softmax(scores, dim=-1)

        # 加权求和
        output = torch.matmul(attention_weights, V)

        return output, attention_weights

    def forward(self, x, mask=None):
        batch_size = x.size(0)

        # 线性变换
        Q = self.W_Q(x)  # (batch, seq_len, d_model)
        K = self.W_K(x)
        V = self.W_V(x)

        # 分割多头
        Q = Q.view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        K = K.view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        V = V.view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)

        # 计算注意力
        output, attention_weights = self.scaled_dot_product_attention(Q, K, V, mask)

        # 合并多头
        output = output.transpose(1, 2).contiguous().view(batch_size, -1, self.d_model)

        return output, attention_weights
``` 

### 1.1.4 Multi-Head Attention

多头注意力使用多个注意力头，每个头学习不同的表示。

**原理**：
```
多头注意力 = 多个注意力头的输出拼接 + 线性变换

MultiHead(Q, K, V) = Concat(head₁, ..., head_h) · W_O

head_i = Attention(QW_i^Q, KW_i^K, VW_i^V)
``` 

**优势**：
- 每个头关注不同的信息
- 捕捉不同的表示子空间
- 更强大的表达能力

**代码实现**：
```python
class MultiHeadAttention(nn.Module):
    def __init__(self, d_model, num_heads):
        super().__init__()
        assert d_model % num_heads == 0

        self.d_model = d_model
        self.num_heads = num_heads
        self.d_k = d_model // num_heads

        # 线性变换
        self.W_Q = nn.Linear(d_model, d_model)
        self.W_K = nn.Linear(d_model, d_model)
        self.W_V = nn.Linear(d_model, d_model)
        self.W_O = nn.Linear(d_model, d_model)

    def scaled_dot_product_attention(self, Q, K, V, mask=None):
        # 计算注意力分数
        scores = torch.matmul(Q, K.transpose(-2, -1)) / torch.sqrt(self.d_k)

        # 应用mask（如果有）
        if mask is not None:
            scores = scores.masked_fill(mask == 0, -1e9)

        # 计算注意力权重
        attention_weights = F.softmax(scores, dim=-1)

        # 加权求和
        output = torch.matmul(attention_weights, V)

        return output, attention_weights

    def forward(self, query, key, value, mask=None):
        batch_size = query.size(0)

        # 线性变换
        Q = self.W_Q(query)
        K = self.W_K(key)
        V = self.W_V(value)

        # 分割多头
        Q = Q.view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        K = K.view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        V = V.view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)

        # 计算多头注意力
        output, attention_weights = self.scaled_dot_product_attention(Q, K, V, mask)

        # 合并多头
        output = output.transpose(1, 2).contiguous().view(batch_size, -1, self.d_model)

        # 输出层
        output = self.W_O(output)

        return output, attention_weights
``` 

### 1.1.5 Positional Encoding

Transformer没有循环结构，需要位置信息。

**原理**：
```
使用可学习的位置编码或固定的正弦余弦编码

PE(pos, 2i) = sin(pos / 10000^(2i/d_model))
PE(pos, 2i+1) = cos(pos / 10000^(2i/d_model))

pos: 位置索引
i: 维度索引
d_model: 模型维度
``` 

**为什么使用正弦余弦**：
- 可以处理任意长度的序列
- 相对位置编码
- 位置编码有外推性

**代码实现**：
```python
class PositionalEncoding(nn.Module):
    def __init__(self, d_model, max_len=5000):
        super().__init__()

        # 创建位置编码矩阵
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-math.log(10000.0) / d_model))

        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)

        pe = pe.unsqueeze(0)  # (1, max_len, d_model)
        self.register_buffer('pe', pe)

    def forward(self, x):
        # x: (batch, seq_len, d_model)
        x = x + self.pe[:, :x.size(1), :]
        return x
``` 

### 1.1.6 Feed-Forward Networks

前馈网络在每个位置独立处理。

**结构**：
```
FFN(x) = max(0, xW₁ + b₁)W₂ + b₂

通常使用两个线性变换和一个ReLU激活
``` 

**维度变化**：
```
输入: d_model
中间层: d_ff (通常是4*d_model)
输出: d_model
``` 

**代码实现**：
```python
class FeedForward(nn.Module):
    def __init__(self, d_model, d_ff=2048, dropout=0.1):
        super().__init__()
        self.linear1 = nn.Linear(d_model, d_ff)
        self.linear2 = nn.Linear(d_ff, d_model)
        self.dropout = nn.Dropout(dropout)

    def forward(self, x):
        x = F.relu(self.linear1(x))
        x = self.dropout(x)
        x = self.linear2(x)
        return x
``` 

### 1.1.7 Layer Normalization

层归一化稳定训练，加速收敛。

**原理**：
```
LN(x) = γ · (x - μ) / σ + β

μ = (1/m) Σ x_i  # 均值
σ = √((1/m) Σ (x_i - μ)² + ε)  # 方差
γ, β: 可学习的缩放和平移参数
m: 归一化维度
``` 

**在Transformer中的位置**：
```
LayerNorm(x + Sublayer(x))

Sublayer: 自注意力或前馈网络
``` 

**代码实现**：
```python
class LayerNorm(nn.Module):
    def __init__(self, features, eps=1e-6):
        super().__init__()
        self.a_2 = nn.Parameter(torch.ones(features))
        self.b_2 = nn.Parameter(torch.zeros(features))
        self.eps = eps

    def forward(self, x):
        mean = x.mean(-1, keepdim=True)
        std = x.std(-1, keepdim=True)
        return self.a_2 * (x - mean) / (std + self.eps) + self.b_2
``` 

### 1.1.8 Residual Connections

残差连接帮助深层网络训练。

**原理**：
```
Output = x + Sublayer(x)

通过梯度流减少梯度消失
``` 

**在Transformer中的使用**：
```
# Encoder层
x = x + MultiHeadAttention(Q, K, V, mask)
x = x + LayerNorm(x)

# Decoder层
x = x + MultiHeadAttention(Q, K, V, mask)
x = x + MultiHeadAttention(Q, K, V, encoder_output, mask)
x = x + FeedForward(x)
x = x + LayerNorm(x)
``` 

---

## 1.2 模型组件详解

### 1.2.1 Transformer Encoder

编码器由N层相同的层堆叠而成。

**结构**：
```
Encoder Layer:
  ├─ Multi-Head Self-Attention
  │   ├─ 输入投影
  │   ├─ 残差连接
  │   └─ Layer Norm
  │
  ├─ Feed-Forward Network
  │   ├─ 输入投影
  │   ├─ 残差连接
  │   └─ Layer Norm
``` 

**完整实现**：
```python
class TransformerEncoderLayer(nn.Module):
    def __init__(self, d_model, num_heads, d_ff, dropout=0.1):
        super().__init__()

        # Self-Attention
        self.self_attention = MultiHeadAttention(d_model, num_heads)
        self.norm1 = LayerNorm(d_model)
        self.dropout1 = nn.Dropout(dropout)

        # Feed-Forward
        self.feed_forward = FeedForward(d_model, d_ff, dropout)
        self.norm2 = LayerNorm(d_model)
        self.dropout2 = nn.Dropout(dropout)

    def forward(self, x, mask=None):
        # Self-Attention
        attn_output, _ = self.self_attention(x, x, x, mask)
        x = x + self.dropout1(attn_output)
        x = self.norm1(x)

        # Feed-Forward
        ff_output = self.feed_forward(x)
        x = x + self.dropout2(ff_output)
        x = self.norm2(x)

        return x
``` 

### 1.2.2 Transformer Decoder

解码器比编码器多一层交叉注意力。

**结构**：
```
Decoder Layer:
  ├─ Masked Self-Attention
  │   └─ 自回归掩码
  ├─ Feed-Forward Network
  └─ Cross-Attention
      └─ 查询来自解码器，键值来自编码器
``` 

**代码实现**：
```python
class TransformerDecoderLayer(nn.Module):
    def __init__(self, d_model, num_heads, d_ff, dropout=0.1):
        super().__init__()

        # Masked Self-Attention
        self.masked_self_attention = MultiHeadAttention(d_model, num_heads)
        self.norm1 = LayerNorm(d_model)
        self.dropout1 = nn.Dropout(dropout)

        # Cross-Attention
        self.cross_attention = MultiHeadAttention(d_model, num_heads)
        self.norm2 = LayerNorm(d_model)
        self.dropout2 = nn.Dropout(dropout)

        # Feed-Forward
        self.feed_forward = FeedForward(d_model, d_ff, dropout)
        self.norm3 = LayerNorm(d_model)
        self.dropout3 = nn.Dropout(dropout)

    def forward(self, x, encoder_output, src_mask=None, tgt_mask=None):
        # Masked Self-Attention
        attn_output, _ = self.masked_self_attention(x, x, x, tgt_mask)
        x = x + self.dropout1(attn_output)
        x = self.norm1(x)

        # Cross-Attention
        attn_output, _ = self.cross_attention(x, encoder_output, encoder_output, src_mask)
        x = x + self.dropout2(attn_output)
        x = self.norm2(x)

        # Feed-Forward
        ff_output = self.feed_forward(x)
        x = x + self.dropout3(ff_output)
        x = self.norm3(x)

        return x
``` 

### 1.2.3 输入输出处理

**输入处理**：
```
原始文本 → 分词 → 词汇表ID → Embedding → Positional Encoding
``` 

**输出处理**：
```
模型输出 → Softmax → 概率分布 → 词汇表
``` 

**代码实现**：
```python
class Transformer(nn.Module):
    def __init__(self, vocab_size, d_model, num_heads, num_layers, d_ff, max_len=5000, dropout=0.1):
        super().__init__()

        self.embedding = nn.Embedding(vocab_size, d_model)
        self.pos_encoding = PositionalEncoding(d_model, max_len)

        # Encoder
        self.encoder_layers = nn.ModuleList([
            TransformerEncoderLayer(d_model, num_heads, d_ff, dropout)
            for _ in range(num_layers)
        ])

        # Decoder
        self.decoder_layers = nn.ModuleList([
            TransformerDecoderLayer(d_model, num_heads, d_ff, dropout)
            for _ in range(num_layers)
        ])

        # Output projection
        self.output = nn.Linear(d_model, vocab_size)

    def create_mask(self, src, tgt):
        # 源序列mask（防止看到未来）
        src_mask = (src != 0).unsqueeze(1).unsqueeze(2)  # (batch, 1, 1, src_len)

        # 目标序列mask（自回归）
        tgt_mask = (tgt != 0).unsqueeze(1).unsqueeze(2)  # (batch, 1, tgt_len, tgt_len)
        tgt_mask = tgt_mask * (1 - torch.triu(torch.ones_like(tgt_mask), diagonal=1))  # 下三角

        return src_mask, tgt_mask

    def forward(self, src, tgt):
        src_mask, tgt_mask = self.create_mask(src, tgt)

        # Embedding + Positional Encoding
        src_embed = self.pos_encoding(self.embedding(src))
        tgt_embed = self.pos_encoding(self.embedding(tgt))

        # Encoder
        encoder_output = src_embed
        for layer in self.encoder_layers:
            encoder_output = layer(encoder_output, src_mask)

        # Decoder
        decoder_output = tgt_embed
        for layer in self.decoder_layers:
            decoder_output = layer(decoder_output, encoder_output, src_mask, tgt_mask)

        # Output
        output = self.output(decoder_output)

        return output
``` 

---

## 本章小结

本章详细讲解了Transformer架构：

1. **自注意力机制**：核心组件
2. **多头注意力**：多个注意力头
3. **位置编码**：注入位置信息
4. **前馈网络**：非线性变换
5. **层归一化**：稳定训练
6. **残差连接**：深层训练
7. **完整实现**：编码器和解码器

Transformer是现代大模型的基础，几乎所有现代大语言模型都基于此架构。

---

## 习题与思考

1. 解释为什么Transformer不需要RNN或CNN？
2. 自注意力机制中的Q、K、V各代表什么？它们的作用是什么？
3. 什么是多头注意力？为什么需要多头？
4. 为什么使用残差连接？有什么好处？
5. 位置编码的作用是什么？为什么使用正弦余弦编码？

## 参考资料

1. "Attention Is All You Need" - Transformer原论文
2. "BERT: Pre-training of Deep Bidirectional Transformers" - BERT论文
3. "The Illustrated Transformer" - Jay Alammar的博客
4. "Vision Transformer (ViT)" - Vision Transformer论文

## 代码示例

```python
# 完整的Transformer模型
import math
import torch
import torch.nn as nn
import torch.nn.functional as F

class PositionalEncoding(nn.Module):
    """位置编码"""
    def __init__(self, d_model, max_len=5000):
        super().__init__()
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-math.log(10000.0) / d_model))

        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0)
        self.register_buffer('pe', pe)

    def forward(self, x):
        x = x + self.pe[:, :x.size(1), :]
        return x

class MultiHeadAttention(nn.Module):
    """多头注意力"""
    def __init__(self, d_model, num_heads):
        super().__init__()
        assert d_model % num_heads == 0
        self.d_model = d_model
        self.num_heads = num_heads
        self.d_k = d_model // num_heads

        self.W_Q = nn.Linear(d_model, d_model)
        self.W_K = nn.Linear(d_model, d_model)
        self.W_V = nn.Linear(d_model, d_model)
        self.W_O = nn.Linear(d_model, d_model)

    def scaled_dot_product_attention(self, Q, K, V, mask=None):
        scores = torch.matmul(Q, K.transpose(-2, -1)) / torch.sqrt(self.d_k)
        if mask is not None:
            scores = scores.masked_fill(mask == 0, -1e9)
        attention_weights = F.softmax(scores, dim=-1)
        output = torch.matmul(attention_weights, V)
        return output, attention_weights

    def forward(self, query, key, value, mask=None):
        batch_size = query.size(0)
        Q = self.W_Q(query).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        K = self.W_K(key).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)
        V = self.W_V(value).view(batch_size, -1, self.num_heads, self.d_k).transpose(1, 2)

        output, _ = self.scaled_dot_product_attention(Q, K, V, mask)
        output = output.transpose(1, 2).contiguous().view(batch_size, -1, self.d_model)
        return self.W_O(output)

class LayerNorm(nn.Module):
    """层归一化"""
    def __init__(self, features, eps=1e-6):
        super().__init__()
        self.a_2 = nn.Parameter(torch.ones(features))
        self.b_2 = nn.Parameter(torch.zeros(features))
        self.eps = eps

    def forward(self, x):
        mean = x.mean(-1, keepdim=True)
        std = x.std(-1, keepdim=True)
        return self.a_2 * (x - mean) / (std + self.eps) + self.b_2

class FeedForward(nn.Module):
    """前馈网络"""
    def __init__(self, d_model, d_ff=2048, dropout=0.1):
        super().__init__()
        self.linear1 = nn.Linear(d_model, d_ff)
        self.linear2 = nn.Linear(d_ff, d_model)
        self.dropout = nn.Dropout(dropout)

    def forward(self, x):
        return self.dropout(F.relu(self.linear1(x))) @ self.linear2

class TransformerEncoderLayer(nn.Module):
    """Transformer编码器层"""
    def __init__(self, d_model, num_heads, d_ff, dropout=0.1):
        super().__init__()
        self.self_attention = MultiHeadAttention(d_model, num_heads)
        self.norm1 = LayerNorm(d_model)
        self.dropout1 = nn.Dropout(dropout)

        self.feed_forward = FeedForward(d_model, d_ff, dropout)
        self.norm2 = LayerNorm(d_model)
        self.dropout2 = nn.Dropout(dropout)

    def forward(self, x, mask=None):
        attn_output = self.self_attention(x, x, x, mask)
        x = x + self.dropout1(attn_output)
        x = self.norm1(x)

        ff_output = self.feed_forward(x)
        x = x + self.dropout2(ff_output)
        x = self.norm2(x)
        return x

class Transformer(nn.Module):
    """完整的Transformer"""
    def __init__(self, vocab_size, d_model, num_heads, num_layers, d_ff, max_len=5000, dropout=0.1):
        super().__init__()
        self.embedding = nn.Embedding(vocab_size, d_model)
        self.pos_encoding = PositionalEncoding(d_model, max_len)

        self.encoder_layers = nn.ModuleList([
            TransformerEncoderLayer(d_model, num_heads, d_ff, dropout)
            for _ in range(num_layers)
        ])
        self.output = nn.Linear(d_model, vocab_size)

    def create_mask(self, src, tgt):
        src_mask = (src != 0).unsqueeze(1).unsqueeze(2)
        tgt_mask = (tgt != 0).unsqueeze(1).unsqueeze(2)
        tgt_mask = tgt_mask * (1 - torch.triu(torch.ones_like(tgt_mask), diagonal=1))
        return src_mask, tgt_mask

    def forward(self, src, tgt):
        src_mask, tgt_mask = self.create_mask(src, tgt)

        src_embed = self.pos_encoding(self.embedding(src))
        for layer in self.encoder_layers:
            src_embed = layer(src_embed, src_mask)

        return self.output(src_embed)

# 使用示例
vocab_size = 30522
d_model = 512
num_heads = 8
num_layers = 6
d_ff = 2048

model = Transformer(vocab_size, d_model, num_heads, num_layers, d_ff)

# 模拟数据
src = torch.randint(0, vocab_size, (32, 128))  # batch_size=32, src_len=128
tgt = torch.randint(0, vocab_size, (32, 64))   # batch_size=32, tgt_len=64

output = model(src, tgt)

print(f"Source shape: {src.shape}")       # (32, 128)
print(f"Target shape: {tgt.shape}")       # (32, 64)
print(f"Output shape: {output.shape}")    # (32, 128, 30522)
```