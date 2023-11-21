import pandas as pd

df = pd.read_csv('sales_data_sample.csv', encoding='latin1')
print("Dữ liệu đã được đọc thành công.")


#Xử lý giá trị null
df_cleaned = df.dropna()
print("Các giá trị null đã được xử lý.")

#Chuyển đổi kiểu dữ liệu của cột ORDERDATE
df_cleaned['ORDERDATE'] = pd.to_datetime(df_cleaned['ORDERDATE'])
print("Cột ORDERDATE đã được chuyển đổi thành kiểu datetime.")

#Kiểm tra giá trị duy nhất trong cột STATUS
unique_statuses = df_cleaned['STATUS'].unique()

print(f"STATUS: {unique_statuses}")
print(df_cleaned.info())

# Lưu DataFrame đã được xử lý thành một tệp CSV
df_cleaned.to_csv("sales_data_sample.csv", index=False)

